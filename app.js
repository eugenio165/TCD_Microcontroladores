//Configurações do Servidor
var express = require('express');
var app = express();
const port = 3000;
// Usado para comunicação em tempo real
var server = require('http').Server(app);
var io = require('socket.io')(server);
// Usado para ler o corpo do request POST
var bodyParser = require('body-parser');
// Determina em qual plataforma está sendo executado o servidor
var isWin = process.platform === "win32";
// Usado apra armazenar os estados dos leds
var ledQty = 3;
var ledStatus = [false, false, false];

// // Pacote usado para deixar o servidor no ar, na internet
// const ngrok = require('ngrok');
// var url;
// (async function() {
//     url = await ngrok.connect(port);
//     console.log(url);
// })();

// Pacotes para comunicar com o PIC
const SerialPort = require('@serialport/stream');
const MockBinding = require('@serialport/binding-mock');
SerialPort.Binding = MockBinding;

// // Create a port and enable the echo and recording.
// MockBinding.createPort('/dev/ROBOT', { echo: true, record: true });
// const options = {
//     baudRate: 9600,
//     dataBits: 8,
//     stopBits: 1,
//     autoOpen: true,
// };
// const microport = new SerialPort('/dev/ROBOT', options);

// // Switches the port into "flowing mode"
// microport.on('data', function (data) {
//     console.log('Data:', data)
// });

// Habilitando o entendimento de dados passados por POST
app.use(bodyParser.urlencoded({
    extended: true,
}));
app.use(bodyParser.json());

// Disponibilizando a aplicação do site feito em angular
app.use(express.static(__dirname + '/TCD_Microcontroladores_Site/dist'));

// Enviando o index do site quando alguem bater no link do site
app.get('/', function(req, res){
    res.sendFile(__dirname + '/TCD_Microcontroladores_Site/dist/index.html');
});

// Usado para redirecionar os pedidos em qualquer link
app.get('*', function(req, res){
    res.redirect("/");
});

server.listen(port, (succ, err) => {
    console.log("Servidor ativo na porta: " + port);
});

// Trata da conexão do websocket (comunicação em tempo real)
io.on('connection', function (socket) {
    console.log('conectou mais um');
    // Ao conectar, envie o status atual dos LEDS
    socket.emit('led status', ledStatus);

    // Ao receber um pedido de alteração de estado do led...
    socket.on('led toggle', function (index) {
        console.log(index);
        ledStatus[index] = !ledStatus[index];
        // Passa para o PIC qual led é para ser apagado/ligado / RECEBE DO PIC O ESTADO DO LED
        io.emit('led change', { index: index, state: ledStatus[index]});
    });

    // Ao receber um pedido de configuração da pagina de ADMIN...
    socket.on('led options', function (qty) {
        console.log(qty);
        // Passa para o PIC quantos LEDS é para ser usado / RECEBE DO PIC OS ESTADOS DOS LEDS E ATUALIA CONTADOR
    });
});
