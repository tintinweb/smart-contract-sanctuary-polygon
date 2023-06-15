// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/** CUASI SUBASTA INGLESA
 *
 * Descripción:
 * Tienen la tarea de crear un contrato inteligente que permita crear subastas Inglesas (English auction).
 * Se paga 1 Ether para crear una subasta y se debe especificar su hora de inicio y finalización.
 * Los ofertantes envian sus ofertas a la subasta que ellos deseen durante el tiempo que la subasta esté abierta.
 * Cada subasta tiene un ID único que permite a los ofertantes identificar la subasta a la que desean ofertar.
 * Los ofertantes para poder proponer su oferta envían Ether al contrato (llamando al método 'proponerOferta' o enviando directamente).
 * Las ofertas deben ser mayores a la oferta más alta actual para una subasta en particular.
 * Si se realiza una oferta dentro de los 5 minutos finales de la subasta, el tiempo de finalización se extiende en 5 minutos
 * Una vez que el tiempo de la subasta se cumple, cualquier puede llamar al método 'finalizarSubasta' para finalizar la subasta.
 * Cuando finaliza la subasta, el ganador recupera su oferta y se lleva el 1 Ether depositado por el creador.
 * Cuando finaliza la subasta se emite un evento con el ganador (address)
 * Las personas que no ganaron la subasta pueden recuperar su oferta después de que finalice la subasta
 *
 * ¿Qué es una subasta Inglesa?
 * En una subasta inglesa el precio comienza bajo y los postores pujan el precio haciendo ofertas.
 * Cuando se cierra la subasta, se emite un evento con el mejor postor.
 *
 * Métodos a implementar:
 * - El método 'creaSubasta(uint256 _startTime, uint256 _endTime)':
 *      * Crea un ID único del typo bytes32 para la subasta y lo guarda en la lista de subastas activas
 *      * Permite a cualquier usuario crear una subasta pagando 1 Ether
 *          - Error en caso el usuario no envíe 1 Ether: CantidadIncorrectaEth();
 *      * Verifica que el tiempo de finalización sea mayor al tiempo de inicio
 *          - Error en caso el tiempo de finalización sea mayo al tiempo de inicio: TiempoInvalido();
 *      * Disparar un evento llamado 'SubastaCreada' con el ID de la subasta y el creador de la subasta (address)
 *
 * - El método 'proponerOferta(bytes32 _auctionId)':
 *      * Verifica que ese ID de subasta (_auctionId) exista
 *          - Error si el ID de subasta no existe: SubastaInexistente();
 *      * Usando el ID de una subasta (_auctionId), el ofertante propone una oferta y envía Ether al contrato
 *          - Error si la oferta no es mayor a la oferta más alta actual: OfertaInvalida();
 *      * Solo es llamado durante el tiempo de la subasta (entre el inicio y el final)
 *          - Error si la subasta no está en progreso: FueraDeTiempo();
 *      * Emite el evento 'OfertaPropuesta' con el postor y el monto de la oferta
 *      * Guarda la cantidad de Ether enviado por el postor para luego poder recuperar su oferta en caso no gane la subasta
 *      * Añade 5 minutos al tiempo de finalización de la subasta si la oferta se realizó dentro de los últimos 5 minutos
 *      Nota: Cuando se hace una oferta, incluye el Ether enviado anteriormente por el ofertante
 *
 * - El método 'finalizarSubasta(bytes32 _auctionId)':
 *      * Verifica que ese ID de subasta (_auctionId) exista
 *          - Error si el ID de subasta no existe: SubastaInexistente();
 *      * Es llamado luego del tiempo de finalización de la subasta usando su ID (_auctionId)
 *          - Error si la subasta aún no termina: SubastaEnMarcha();
 *      * Elimina el ID de la subasta (_auctionId) de la lista de subastas activas
 *      * Emite el evento 'SubastaFinalizada' con el ganador de la subasta y el monto de la oferta
 *      * Añade 1 Ether al balance del ganador de la subasta para que éste lo puedo retirar después
 *
 * - El método 'recuperarOferta(bytes32 _auctionId)':
 *      * Permite a los usuarios recuperar su oferta (tanto si ganaron como si perdieron la subasta)
 *      * Verifica que la subasta haya finalizado
 *      * El smart contract le envía el balance de Ether que tiene a favor del ofertante
 *
 * - El método 'verSubastasActivas() returns(bytes32[])':
 *      * Devuelve la lista de subastas activas en un array
 */

contract EnglishAuction {
    struct Auction {
        uint256 startTime;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        mapping(address => uint256) offers;
    }
    mapping(bytes32 => Auction) public auctions;

    // Active auctions
    bytes32[] public activeAuctions;
    mapping(bytes32 idDeSubasta => uint256 indiceEnArray) public auctionIndex;

    // Passed auctions
    bytes32[] public pastAuctions;

    uint256 counter;

    event SubastaCreada(bytes32 indexed _auctionId, address indexed _creator);
    event OfertaPropuesta(address indexed _bidder, uint256 _bid);
    event SubastaFinalizada(address indexed _winner, uint256 _bid);

    function creaSubasta(uint256 _startTime, uint256 _endTime) public payable {
        if (msg.value != 1 wei) revert("Se debe enviar 1 wei");
        if (_endTime <= _startTime)
            revert("Tiempo final debe ser mayor a inicial");

        bytes32 _auctionId = _createId(_startTime, _endTime);
        activeAuctions.push(_auctionId);
        auctionIndex[_auctionId] = counter;
        counter++;

        Auction storage auction = auctions[_auctionId];
        auction.startTime = _startTime;
        auction.endTime = _endTime;

        emit SubastaCreada(_auctionId, msg.sender);
    }

    function proponerOferta(bytes32 _auctionId) public payable {
        Auction storage auction = auctions[_auctionId];

        if (auction.startTime == 0) revert("Subasta no existe");

        if (auction.endTime < block.timestamp) revert("Fuera de tiempo");

        if (auction.offers[msg.sender] + msg.value <= auction.highestBid)
            revert("Oferta Invalida");

        if (auction.endTime - block.timestamp <= 5 minutes)
            auction.endTime += 5 minutes;

        auction.highestBidder = msg.sender;
        auction.highestBid = auction.offers[msg.sender] + msg.value;
        auction.offers[msg.sender] += msg.value;

        emit OfertaPropuesta(msg.sender, auction.offers[msg.sender]);
    }

    function finalizarSubasta(bytes32 _auctionId) public {
        Auction storage auction = auctions[_auctionId];
        if (auction.startTime == 0) revert("Subasta no existe");
        if (auction.endTime > block.timestamp) revert("Subasta en marcha");

        activeAuctions[auctionIndex[_auctionId]] = activeAuctions[
            activeAuctions.length - 1
        ];
        auction.startTime = 0;
        auction.offers[auction.highestBidder] += 1 wei;
        activeAuctions.pop();
        counter--;

        pastAuctions.push(_auctionId);

        emit SubastaFinalizada(auction.highestBidder, auction.highestBid);
    }

    function recuperarOferta(bytes32 _auctionId) public {
        Auction storage auction = auctions[_auctionId];
        if (auction.endTime > block.timestamp || auction.startTime != 0) {
            revert("Subasta en marcha");
        }
        uint256 amount = auction.offers[msg.sender];
        auction.offers[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function verSubastasActivas() public view returns (bytes32[] memory) {
        bytes32[] memory _activeAuctionsId = new bytes32[](
            activeAuctions.length
        );
        for (uint256 i = 0; i < activeAuctions.length; i++) {
            _activeAuctionsId[i] = activeAuctions[i];
        }
        return _activeAuctionsId;
    }

    function verSubastasPasadas() public view returns (bytes32[] memory) {
        return pastAuctions;
    }

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////   INTERNAL METHODS  ///////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////

    function _createId(
        uint256 _startTime,
        uint256 _endTime
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _startTime,
                    _endTime,
                    msg.sender,
                    block.timestamp
                )
            );
    }
}