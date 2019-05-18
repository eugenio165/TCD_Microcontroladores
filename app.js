//Configurações do Servidor
var express = require('express');
var app = express();
const port = 3000;
var favicon = require("serve-favicon");
const open = require('open');

// Usado para comunicação em tempo real
var server = require('http').Server(app);
var io = require('socket.io')(server);

// Usado para ler o corpo do request POST
var bodyParser = require('body-parser');

// Usado apra armazenar os estados dos leds
var ledQty = 3;
var ledStatus = [false, true, false];
const path = require('path');

// Pacote usado para deixar o servidor no ar, na internet
const ngrok = require('ngrok');
var url = 'localhost:3000';

// Pacote para comunicar com o PIC
const SerialPort = require('serialport');
const options = {
    baudRate: 9600,
    dataBits: 8,
    stopBits: 1,
    autoOpen: true,
};

const microport = new SerialPort('/dev/ttyUSB0', options, err => {
    if (err)
        return console.log('Erro ao abrir a porta!\n', err.message);
});

microport.on('error', err => {
    console.log('Erro na porta!:\n ', err.message);
});

// Ao abrir, recebe o estado dos leds e seta o trisb
microport.on('open', () => {
    // Manda o codigo 11 pra pegar o status dos LEDS
    console.log('PORTA DO PIC ABERTA COM SUCESSO!');
    microport.write(Buffer.from([11, 9]));
});

var started = false;
var ledIndex = -1;
var status = false;
// Switches the port into "flowing mode"
microport.on('data', (data) => {
    let int = data.readUInt8(0);
    // console.log('hi', status);
    if (!status) {
        console.log('PIC> ', int);
    }
    if (status) {
        status = false;
        let binary = int.toString(2);
        // console.log(binary);
        if (binary.length == 1)
            ledQty = 8;
        else {
            let counter = 0;
            for (let i = 0; i < binary.length; i++) {
                if (binary[i] == 0)
                counter++;
            }
            ledQty = counter;
        }
        console.log('TRISB> ', ledQty);
        const newStatus = [];
        for (let index = 0; index < ledQty; index++) {
            newStatus.push(false);
        }
        ledStatus = newStatus;
        if (!started) {
            (async () => {
                url = await ngrok.connect(port);
                console.log(url);
                open(url);
            })();
            started = true;
        }
    } else if (int == 9) {
        ledStatus = ledStatus.map(state => false);
    } else if (int == 10) {
        ledStatus = ledStatus.map(state => true);
    } else if (int <= 7) {
        if (ledIndex == -1)
            ledIndex = int;
        else {
            ledStatus[ledIndex] = (int == 1) ? true : false;
            ledIndex = -1;
        }
    } else if (int == 11)
        status = true;
    io.emit('led status', ledStatus);
});

// Configurando conexão com o servidor


app.set('view engine', 'pug');
// Habilitando o entendimento de dados passados por POST
app.use(bodyParser.urlencoded({
    extended: true,
}));
app.use(bodyParser.json());

// Disponibilizando a aplicação do site feito em angular
app.set("views", __dirname + "/views");
// app.use(express.static(__dirname + '/views'));
app.use(express.static(path.join(__dirname, "public")));
app.use(favicon(path.join(__dirname, "public", "assets", "iot.ico")));

// Enviando o index do site quando alguem bater no link do site
app.get('/', (req, res) => {
    res.render('principal', { serverurl: url, route: 'principal' });
});

app.get('/admin', (req, res) => {
    res.render('admin', { serverurl: url, route: 'admin' });
});

// Usado para redirecionar os pedidos em qualquer link
app.get('*', (req, res) => {
    res.redirect("/");
});

server.listen(port, (succ, err) => {
    console.log("Servidor ativo na porta: " + port);
    // open('http://localhost:3000');
});



// Trata da conexão do websocket (comunicação em tempo real)
var connections = 0;
io.on('connection', (socket) => {
    connections++;
    io.emit('connections', connections);
    console.log('SOCKET> NEW CONNECTION');
    // Ao conectar, envie o status atual dos LEDS
    socket.emit('led status', ledStatus);

    // Ao receber um pedido de alteração de estado do led...
    socket.on('led toggle', (index) => {
        // Passa para o PIC qual led é para ser apagado/ligado / RECEBE DO PIC O ESTADO DO LED
        microport.write(Buffer.from([index]));
    });

    // Ao receber um pedido para ligar todos os LEDs...
    socket.on('led on', (index) => {
        microport.write(Buffer.from([10]));
    });

    // Ao receber um pedido para apagar todos os LEDs...
    socket.on('led off', (index) => {
        microport.write(Buffer.from([9]));
    });

    // Ao receber um pedido de configuração da pagina de ADMIN...
    socket.on('led options', (config) => {
        let binaryConfig = Math.pow(2, config) -1;
        let trisb = 255 - binaryConfig;
        microport.write(Buffer.from([8, trisb, 11]));
    });
    socket.on('disconnect', () => {
        connections--;
        io.emit('connections', connections);
    })
});