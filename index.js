//Configurações do Servidor
var express = require('express');
var app = express();
var bodyParser = require('body-parser');
const port = 3000;

// Pacotes para comunicar com o PIC
const SerialPort = require('@serialport/stream');
const MockBinding = require('@serialport/binding-mock');
SerialPort.Binding = MockBinding;

// Create a port and enable the echo and recording.
MockBinding.createPort('/dev/ROBOT', { echo: true, record: true });
const options = {
    baudRate: 9600,
    dataBits: 8,
    stopBits: 1,
    autoOpen: true,
};
const microport = new SerialPort('/dev/ROBOT', options);

// Switches the port into "flowing mode"
microport.on('data', function (data) {
    console.log('Data:', data)
});

// Habilitando o entendimento de dados passados por POST
app.use(bodyParser.urlencoded({
    extended: true,
}));
app.use(bodyParser.json());

// Disponibilizando as paginas
app.get('/', function(req, res){
    res.sendFile(path.join(__dirname + '/index.html'));
});

app.listen(port, (succ, err) => {
    console.log("Listening on port: " + port);
});

app.post('/', function(req, res) {
    console.log(req.body);
    return res.json('ok');
});
