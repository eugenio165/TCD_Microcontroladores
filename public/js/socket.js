var SERVER_URL = '#{URL}';
var socket = io(SERVER_URL, {reconnectionAttempts: 6, reconnectionDelayMax: 3000});
var connection = 'conectando';

window.onload = function () {
    var status  = document.getElementById('statusbtn');
    window.status = status;
    socket.on('connect', (data) => {
        status.classList.remove('btn-primary','btn-danger', 'btn-info', 'btn-success');
        status.classList.add('btn-success');
    });
    socket.on('reconnecting', (data) => {
        status.classList.remove('btn-primary','btn-danger', 'btn-info', 'btn-success');
        status.classList.add('btn-info');
    });
    socket.on('reconnect_failed', () => {
        status.classList.remove('btn-primary','btn-danger', 'btn-info', 'btn-success');
        status.classList.add('btn-danger');
    });
}

//- socket.on('led status', (status) => {
//-     var LEDS = status.map(s => {
//-         return {state: s, querying = false};
//-     });
//-     console.log(status);
//- });