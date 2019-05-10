//Configurações do Servidor
var express = require('express');
var app = express();
const port = 3000;

// Usado para comunicação em tempo real
var server = require('http').Server(app);
var io = require('socket.io')(server);

// Usado para ler o corpo do request POST
var bodyParser = require('body-parser');

// Usado apra armazenar os estados dos leds
var ledQty = 3;
var ledStatus = [false, false, false];
const path = require('path');

// Pacote usado para deixar o servidor no ar, na internet
// const ngrok = require('ngrok');
// var url;
// (async() => {
//     url = await ngrok.connect(port);
//     console.log(url);
// })();

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
    console.log('ABRIU LOGO NO INICIO');
});

//TODO: Test ledstatus receiver
microport.on('error', err => {
    console.log('Erro na porta!:\n ', err.message);
});

// Ao abrir, recebe o estado dos leds e seta o trisb
microport.on('open', () => {
    console.log('ABRIU abriu');
    // Manda o codigo 11 pra pegar o status dos LEDS
    microport.write(Buffer.from([11]), (err, f) => {
        console.log('depois do status', err, f);
    });
});

// Switches the port into "flowing mode"
microport.on('data', (data) => {
    console.log('FROM PIC: ' + typeof data);
    console.log('IS: ', data);
    console.log('PIC> ', data.values());
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

// Enviando o index do site quando alguem bater no link do site
app.get('/', (req, res) => {
    res.render('principal', {serverurl: 'localhost:3000', route: 'principal'});
});

app.get('/admin', (req, res) => {
    res.render('admin', {serverurl: 'localhost:3000', route: 'admin'});
});

// Usado para redirecionar os pedidos em qualquer link
app.get('*', (req, res) => {
    res.redirect("/");
});

server.listen(port, (succ, err) => {
    console.log("Servidor ativo na porta: " + port);
});



// Trata da conexão do websocket (comunicação em tempo real)



io.on('connection', (socket) => {
    console.log('SOCKET> NEW CONNECTION');
    // Ao conectar, envie o status atual dos LEDS
    socket.emit('led status', ledStatus);

    // Ao receber um pedido de alteração de estado do led...
    socket.on('led toggle', (index) => {
        ledStatus[index] = !ledStatus[index];
        // Passa para o PIC qual led é para ser apagado/ligado / RECEBE DO PIC O ESTADO DO LED
        microport.write(Buffer.from([index]), (err, f) => {
            console.log('AFTER LED TOGGLE> ', err, f);
        });
        io.emit('led status', ledStatus);
    });

    // Ao receber um pedido para ligar todos os LEDs...
    socket.on('led on', (index) => {
        ledStatus = ledStatus.map(state => true);
        console.log('LEDs OFF');
        microport.write(Buffer.from([10]));
        io.emit('led status', ledStatus);
    });

    // Ao receber um pedido para apagar todos os LEDs...
    socket.on('led off', (index) => {
        ledStatus = ledStatus.map(state => false);
        console.log('LEDs ON');
        microport.write(Buffer.from([9]));
        io.emit('led status', ledStatus);
    });

    // Ao receber um pedido de configuração da pagina de ADMIN...
    socket.on('led options', (config) => {
        console.log(config);
        ledQty = config.ledQty;
        const newStatus = [];
        for (let index = 0; index < ledQty; index++) {
            newStatus.push(false);
        }
        //TODO: Receive led status from pic
        ledStatus = newStatus;
        io.emit('led status', ledStatus);
        // Passa para o PIC quantos LEDS é para ser usado / RECEBE DO PIC OS ESTADOS DOS LEDS E ATUALIA CONTADOR
    });
});