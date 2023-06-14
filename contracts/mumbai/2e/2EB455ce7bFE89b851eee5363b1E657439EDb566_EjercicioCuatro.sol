// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract EjercicioCuatro {
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

    uint256 counter;

    event SubastaCreada(bytes32 indexed _auctionId, address indexed _creator);
    event OfertaPropuesta(address indexed _bidder, uint256 _bid);
    event SubastaFinalizada(address indexed _winner, uint256 _bid);

    error CantidadIncorrectaEth();
    error TiempoInvalido();
    error SubastaInexistente();
    error FueraDeTiempo();
    error OfertaInvalida();
    error SubastaEnMarcha();

    function creaSubasta(uint256 _startTime, uint256 _endTime) public payable {
        if (msg.value != 1 wei) revert CantidadIncorrectaEth();
        if (_endTime <= _startTime) revert TiempoInvalido();

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

        if (auction.startTime == 0) revert SubastaInexistente();

        if (auction.endTime < block.timestamp) revert FueraDeTiempo();

        if (auction.offers[msg.sender] + msg.value <= auction.highestBid)
            revert OfertaInvalida();

        if (auction.endTime - block.timestamp <= 5 minutes)
            auction.endTime += 5 minutes;

        auction.highestBidder = msg.sender;
        auction.highestBid = auction.offers[msg.sender] + msg.value;
        auction.offers[msg.sender] += msg.value;

        emit OfertaPropuesta(msg.sender, auction.offers[msg.sender]);
    }

    function finalizarSubasta(bytes32 _auctionId) public {
        Auction storage auction = auctions[_auctionId];
        if (auction.startTime == 0) revert SubastaInexistente();
        if (auction.endTime > block.timestamp) revert SubastaEnMarcha();

        activeAuctions[auctionIndex[_auctionId]] = activeAuctions[
            activeAuctions.length - 1
        ];
        auction.startTime = 0;
        auction.offers[auction.highestBidder] += 1 wei;
        activeAuctions.pop();
        counter--;

        emit SubastaFinalizada(auction.highestBidder, auction.highestBid);
    }

    function recuperarOferta(bytes32 _auctionId) public {
        Auction storage auction = auctions[_auctionId];
        if (auction.endTime > block.timestamp || auction.startTime != 0) {
            revert SubastaEnMarcha();
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