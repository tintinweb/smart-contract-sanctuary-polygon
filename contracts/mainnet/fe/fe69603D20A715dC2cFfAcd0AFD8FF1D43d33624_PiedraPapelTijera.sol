/**
 *Submitted for verification at polygonscan.com on 2023-03-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title PiedraPapelTijera
 * @author Intilabs
 */

contract PiedraPapelTijera {
    enum Opcion { Piedra, Papel, Tijera }
	enum Estado { Esperando, Jugando, NoJugando }
    struct Jugada {
        address jugador;
        Opcion opcion;
        uint256 apuesta;
        bool jugado;
    }
    struct Jugador {
        uint256 victorias;
        uint256 derrotas;
        Estado estado;
        uint256 balanceJuego; 
    }
	
	event NuevoJugador(address indexed jugador);
	event RetiroJugador(address indexed jugador);
	event JugadorUnido(address indexed jugador);
	event JuegoIniciado(address indexed jugador1, address indexed jugador2);
	event JugadaRealizada(address indexed jugador);
	event FondosTransferidos(address indexed de, address indexed a, uint256 montoJuego, uint256 montoLobby);
	event JugadorRemovido(address indexed jugador);
	event CambioPosicion(address indexed jugadorAnterior, address indexed jugadorNuevo);
	event TurnoJugador(address indexed jugador);

	
    address public owner;
    address[] public jugadoresEnEspera;
    address public jugador1;
    address public jugador2;
    mapping(address => Jugada) public jugadas;
    mapping(address => Jugador) public jugadores;
    mapping(address => uint256) public balancesJuego;
    mapping(address => uint256) public balancesLobby;

    uint256 public tiempoLimite_RJugada = 300;
    uint256 public tiempoInicio;
	uint256 private constant TIEMPO_LIMITE_PARTIDA = 450;

	
	bool internal _notEntered = true;

    uint8[3][3] public matrizResultados = [
        [0, 2, 1],
        [1, 0, 2],
        [2, 1, 0]
    ];

    modifier nonReentrant() {
        require(_notEntered, "ReentrancyGuard: reentrant call");
        _notEntered = false;
        _;
        _notEntered = true;
    }

    constructor() {
        owner = msg.sender;
    }

    modifier soloOwner() {
        require(msg.sender == owner, "Solo el propietario puede realizar esta accion.");
        _;
    }

    modifier soloJugadores() {
        require(jugadores[msg.sender].estado == Estado.Jugando, "No eres un jugador valido.");
        _;
    }
    
    function notificarTurno(address jugador) private {
        emit TurnoJugador(jugador);
    }

	function actualizarJugador(address jugador, uint256 balanceJuego, uint256 balanceLobby) private {
    balancesJuego[jugador] = balanceJuego;
    balancesLobby[jugador] = balanceLobby;
	}


	function transferirFondos(address de, address a, uint256 montoJuego, uint256 montoLobby) private {
    actualizarJugador(de, balancesJuego[de] - montoJuego, balancesLobby[de] - montoLobby);
    actualizarJugador(a, balancesJuego[a] + montoJuego, balancesLobby[a] + montoLobby);
    emit FondosTransferidos(de, a, montoJuego, montoLobby);
	}


	function eliminarJugador(address jugador) private {
    delete jugadores[jugador];
    actualizarJugador(jugador, 0, 0);
    emit JugadorRemovido(jugador);
	}



    function unirseLobby() public payable {
        require(msg.value > 0, "Debes depositar algo de Matic.");
        balancesLobby[msg.sender] += msg.value;
        jugadoresEnEspera.push(msg.sender);
        jugadores[msg.sender].estado = Estado.Esperando;
        emit NuevoJugador(msg.sender);
    }

    function retirarLobby() public {
        require(jugadores[msg.sender].estado == Estado.Esperando, "No estas en el lobby.");
        uint256 balanceLobby = balancesLobby[msg.sender];
        balancesLobby[msg.sender] = 0;
        payable(msg.sender).transfer(balanceLobby);
		jugadores[msg.sender].estado = Estado.NoJugando;
        emit RetiroJugador(msg.sender);
    }

		function tomarLugar() public payable {
		require(jugadores[msg.sender].estado != Estado.Jugando, "Ya estas jugando en esta partida");
		require(msg.value > 0, "Debes realizar una apuesta");
		if (jugador1 == address(0)) {
		// Jugador 1 toma su lugar
		agregarJugador(msg.sender, 1);
		} else if (jugador2 == address(0)) {
		// Jugador 2 toma su lugar
		require(msg.value == balancesJuego[jugador1], "La apuesta debe ser igual a la del otro jugador");
		agregarJugador(msg.sender, 2);
		} else {
		revert("Ya hay dos jugadores en la partida.");
		}
	}

	function agregarJugador(address jugador, uint8 numeroJugador) private {
		require(jugadores[jugador].estado == Estado.Esperando, "El jugador no esta en la lista de jugadores en espera.");
		require(numeroJugador == 1 || numeroJugador == 2, "Numero de jugador invalido.");

    if (numeroJugador == 1) {
        require(jugador1 == address(0), "El jugador 1 ya esta en el juego.");
        jugador1 = jugador;
        emit JugadorUnido(jugador1);
    } else {
        require(jugador2 == address(0), "El jugador 2 ya esta en el juego.");
        jugador2 = jugador;
        emit JugadorUnido(jugador2);
        // Ambos jugadores están listos para jugar, iniciar el temporizador
		tiempoLimite_RJugada = TIEMPO_LIMITE_PARTIDA;
        emit JuegoIniciado(jugador1, jugador2);
    }

		balancesJuego[jugador] = msg.value;
		balancesLobby[jugador] -= msg.value;
		jugadores[jugador].estado = Estado.Jugando;
		tiempoInicio = block.timestamp;
	}
	
function jugar(uint8 _movimientoJugador, uint256 _apuesta) public soloJugadores {
    Jugada storage jugada = jugadas[msg.sender];
    require(!jugada.jugado, "Ya has jugado.");
    require(block.timestamp < tiempoInicio + tiempoLimite_RJugada, "Ya paso el tiempo limite para realizar la jugada.");  
	require(_movimientoJugador >= uint8(Opcion.Piedra) && _movimientoJugador <= uint8(Opcion.Tijera), "Opcion invalida.");
    require(_apuesta > 0, "Debes apostar algo de Matic.");
    require(balancesJuego[msg.sender] >= _apuesta || balancesLobby[msg.sender] >= _apuesta, "No tienes suficiente saldo para realizar la apuesta.");

    balancesJuego[msg.sender] -= _apuesta;
    jugada.jugador = msg.sender;
	jugada.opcion = Opcion(_movimientoJugador);
    jugada.apuesta = _apuesta;
    jugada.jugado = true;
    emit JugadaRealizada(msg.sender);

    // Notificar el turno del otro jugador
    notificarTurno(msg.sender == jugador1 ? jugador2 : jugador1);

    if (jugadas[jugador1].jugado && jugadas[jugador2].jugado) {
        // Aquí puedes agregar la lógica para manejar el resultado del juego y distribuir las recompensas
    } else if (jugador2 != address(0)) {
        tiempoInicio = block.timestamp;
        notificarTurno(jugador2);
    } else {
        notificarTurno(jugador1);
    }
}

function determinarGanador(uint8 movimiento1, uint8 movimiento2) private view returns (uint256) {
    uint256 resultado = matrizResultados[movimiento1][movimiento2];
    return resultado;
}
	
function retirar() public soloJugadores {
    // Verificar si el jugador ha abandonado el juego
    if (jugadas[msg.sender].jugado == false) {
        // El jugador nunca jugó, eliminarlo de la lista de jugadores
        delete jugadores[msg.sender];
        emit JugadorRemovido(msg.sender);
    } else {
        // El jugador ya ha jugado, no puede abandonar el juego
        require(block.timestamp < tiempoInicio + tiempoLimite_RJugada, "Ya ha pasado el tiempo limite para retirar.");

        if (msg.sender == jugador1) {
            // El jugador 1 abandona el juego, transferir fondos al jugador 2
            uint256 balanceJuego = balancesJuego[msg.sender];
            uint256 balanceLobby = balancesLobby[msg.sender];
            balancesJuego[msg.sender] = 0;
            balancesLobby[msg.sender] = 0;
            jugador1 = address(0);
            balancesJuego[jugador2] += balanceJuego;
            balancesLobby[jugador2] += balanceLobby;
            emit CambioPosicion(jugador1, jugador2);
            emit FondosTransferidos(jugador1, jugador2, balanceJuego, balanceLobby);
        } else if (msg.sender == jugador2) {
            // El jugador 2 abandona el juego, transferir fondos al jugador 1
            uint256 balanceJuego = balancesJuego[msg.sender];
            uint256 balanceLobby = balancesLobby[msg.sender];
            balancesJuego[msg.sender] = 0;
            balancesLobby[msg.sender] = 0;
            jugador2 = address(0);
            balancesJuego[jugador1] += balanceJuego;
            balancesLobby[jugador1] += balanceLobby;
            emit CambioPosicion(jugador2, jugador1);
            emit FondosTransferidos(jugador2, jugador1, balanceJuego, balanceLobby);
        }
    }

    // Verificar si el otro jugador ha abandonado el juego
    if (jugador1 == address(0) && jugador2 == address(0)) {
        // Ambos jugadores han abandonado el juego, regresar a la sala de espera
        delete jugadores[msg.sender];
        emit JugadorRemovido(msg.sender);
    }
}

	function cambiarPosicion() public soloJugadores {
		require(jugadores[msg.sender].estado == Estado.Jugando, "No estas jugando en esta partida.");
		require(balancesJuego[msg.sender] == 0, "No puedes cambiar de posicion si tienes fondos en el juego.");
		require(jugador1 != address(0) && jugador2 != address(0), "No hay suficientes jugadores en el juego.");

		address otroJugador = msg.sender == jugador1 ? jugador2 : jugador1;
		uint256 balanceJugador = balancesJuego[msg.sender];
		balancesJuego[msg.sender] = 0;
		balancesJuego[otroJugador] = 0;

		uint256 balanceLobby = balancesLobby[msg.sender];
		balancesLobby[msg.sender] = 0;
		balancesLobby[otroJugador] = 0;

		transferirFondos(msg.sender, otroJugador, balanceJugador, balanceLobby);

		// Actualizar los jugadores y notificar el cambio de posición
		jugador1 = msg.sender == jugador1 ? jugador2 : jugador1;
		jugador2 = msg.sender == jugador2 ? jugador1 : jugador2;

		emit CambioPosicion(msg.sender, otroJugador);
		notificarTurno(jugador1);
}


function regresarLobby() public soloJugadores {
    require(jugadores[msg.sender].balanceJuego == 0, "No puedes regresar al lobby si tienes fondos en el juego.");
    eliminarJugador(msg.sender);
}

function obtenerDatosJugador(address jugador) public view returns (uint256, uint256, uint256) {
    return (
        jugadores[jugador].balanceJuego,
        jugadores[jugador].victorias,
        jugadores[jugador].derrotas
    );
}

function obtenerBalance() public view returns (uint256) {
    require(msg.sender == jugador1 || msg.sender == jugador2, "No eres un jugador valido.");
    return balancesJuego[msg.sender] + balancesLobby[msg.sender];
}

function cambiartiempoLimite_RJugada(uint256 _nuevoTiempo) public soloOwner {
    tiempoLimite_RJugada = _nuevoTiempo;
}

modifier soloJugador(uint8 jugador) {
    require((jugador == 1 && msg.sender == jugador1) || (jugador == 2 && msg.sender == jugador2), "No eres el jugador especificado.");
    _;
}

function cambiarJugador(uint8 jugador, address _nuevoJugador) public soloJugador(jugador) {
    if (jugador == 1) {
        require(jugador2 == address(0), "El segundo jugador ya se unio.");
    }
    transferirFondos(msg.sender, _nuevoJugador, balancesJuego[msg.sender], balancesLobby[msg.sender]);
    if (jugador == 1) {
        jugador1 = _nuevoJugador;
    } else {
        jugador2 = _nuevoJugador;
    }
    emit CambioPosicion(jugador1, jugador2);
}


function obtenerDatosPartida() public view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
    return (
        jugadores[jugador1].victorias,
        jugadores[jugador1].derrotas,
        jugadores[jugador2].victorias,
        jugadores[jugador2].derrotas,
        balancesJuego[jugador1] + balancesJuego[jugador2],
        tiempoInicio + tiempoLimite_RJugada - block.timestamp
    );
}
}