/**
 *Submitted for verification at polygonscan.com on 2022-12-28
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

struct  TRoom
{
    uint        balanceInWei;
    uint        entryPriceInWei;
    uint        loserId;
    uint        maxPlayerCount;
    string      name;
    uint        createdDate;
    uint        playedDate;
    uint        gainPerWinnerInWei;
    uint        feeInWei;
    bool        isEternal;
    uint        startDate;
    uint        endDate;
    address[]   playerWalletList;
}

struct  TCollaborator 
{
    address     wallet;
    string      name;
    uint        shareInM100;
}

struct  TFee
{
    uint        amountInWei;
    uint        date;
}

struct  TDraw
{
    uint        roomId;
    address     wallet;
    uint        entryPriceInWei;
    uint        gainPerWinnerInWei;
    uint        playedDate;
}

//--------------------------------------------------------------------------------
abstract contract   ReentrancyGuard
{
    uint private constant _NOT_ENTERED = 1;
    uint private constant _ENTERED     = 2;

    uint private _status;

    constructor() 
    {       
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant()         // Prevents a contract from calling itself, directly or indirectly.
    {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");    // On the first call to nonReentrant, _notEntered will be true
        _status = _ENTERED;                                                 // Any calls to nonReentrant after this point will fail
        _;
        _status = _NOT_ENTERED;                                             // By storing the original value once again, a refund is triggered (see // https://eips.ethereum.org/EIPS/eip-2200)
    }
}
//--------------------------------------------------------------------------------
contract    RuskoffKill     is ReentrancyGuard
{
    modifier    onlyOwner()         { require(msg.sender==owner);                       _; }
    modifier    onlyAdminOrOwner    { require(msg.sender==owner || msg.sender==admin);  _; }

    TRoom[]                             rooms;
    mapping(string=>uint)       private roomNames;

    uint                        public  roomFeePercentInM100 = 5  *100;     // 5% commission

    uint                        private totalCollaboratorsSharePercent = 0;
    TCollaborator[]             private collaborators;
    mapping(address => string)  private collaboratorNames;

    address                     public  owner;
    address                     private admin;

    TFee[]                      private fees;
    uint                        private overallFee;

    uint                        private randomNonce;

    mapping(uint => TDraw[])    private draws;

    constructor()
    {
        owner = msg.sender;
        admin = msg.sender;

        randomNonce = block.timestamp * block.number;
    }

    event   CreateRoom(uint roomId, uint maxPlayerCount, uint entryPriceInWei, string name, bool isEternal, uint startDate, uint endDate);
    event   CloseRoom(uint id);
    event   ChangeRoomDates(uint roomId, bool oldIsEternal, uint oldStart, uint oldEnd, bool isEternal, uint start, uint end);
    event   FeeDispatch(uint amount, TFee feeObj);
    event   AddPlayerToRoom( uint roomId, uint playerCount); 
    event   GamePlayedInRoom(uint roomId, uint playerCount, uint entryPrice, uint perWinnerGain, uint roomFee, TRoom room); 
    event   UnsubcribePlayer(uint roomId, address playerWallet, uint remainingPlayerCount, uint entryPrice, uint roomBalance);
    event   ChangeCollaboratorWallet(address previousWallet, address newWallet);

    //=============================================================================
    //=============================================================================
    function    createRoom( uint            maxPlayerCount, 
                            uint            entryPriceInWei, 
                            string memory   name,
                            bool            isEternal,
                            uint            startDate,
                            uint            endDate)
                    external 
                    onlyAdminOrOwner
                    returns(uint)
    {
        require(roomNames[name]==0,                 "Room name exists");
        require(maxPlayerCount>1,                   "Two players at least");

        //----- check if viable room

        uint roomFee        = (roomFeePercentInM100 * entryPriceInWei) / (100*100);
        uint perWinnerGain  = ((entryPriceInWei*maxPlayerCount) - roomFee) / (maxPlayerCount-1);

        require(perWinnerGain > entryPriceInWei,    "entryPrice seems to LOW");

        //-----

        if (isEternal)
        {
            startDate = 0;
            endDate   = 5000000000;
        }

        if (startDate>endDate)
        {
            uint v    = startDate;
            startDate = endDate;
            endDate   = v;
        }

        address[] memory  walletList;

        TRoom memory room = TRoom
        ({
            entryPriceInWei     :   entryPriceInWei,
            balanceInWei        :   0,
            loserId             :   99999999,
            maxPlayerCount      :   maxPlayerCount,
            name                :   name,
            createdDate         :   block.timestamp,
            playedDate          :   0,
            gainPerWinnerInWei  :   0,
            feeInWei            :   0,
            isEternal           :   isEternal,
            startDate           :   startDate,
            endDate             :   endDate,
            playerWalletList    :   walletList
        });

        rooms.push(room);

        roomNames[name] = rooms.length;     // sauve l'ID+1

        emit CreateRoom(rooms.length-1 /*ID*/ , maxPlayerCount, entryPriceInWei, name, isEternal, startDate, endDate);

        return rooms.length;
    }
    //=============================================================================
    function    closeRoom(uint id)  external     onlyAdminOrOwner
    {
        require(id < rooms.length,      "Invalid ID");
        
        TRoom storage room = rooms[id];

        for(uint i; i<room.playerWalletList.length; i++)        // Refund all participants
        {
            (bool sent,) = room.playerWalletList[i].call{value: room.entryPriceInWei}("");    require(sent, "Failed sending back bet amount");
        }

        address[] memory  walletList;

        room.playerWalletList = walletList;         // on part avec une liste fraiche = SANS RIEN DEDANS

        emit CloseRoom(id);
    }
    //=============================================================================
    function    addPlayerToRoom(uint roomId) external payable   nonReentrant
    {
        require(roomId<rooms.length,   "Bad Id for room");

        TRoom storage room = rooms[roomId - 1];

        if (room.isEternal==false)
        {
            require(block.timestamp>=room.startDate && block.timestamp<=room.endDate, "The room is currently closed");
        }

        require(msg.value==room.entryPriceInWei,    "Entry price invalid");

        for(uint i; i<room.playerWalletList.length; i++)
        {
            if (msg.sender==room.playerWalletList[i])
            {
                revert("Player already participating");
            }
        }

        require(room.playerWalletList.length < room.maxPlayerCount, "too many participants");

        //-----

        room.playerWalletList.push(msg.sender);
        room.balanceInWei += room.entryPriceInWei;

        if (room.playerWalletList.length==room.maxPlayerCount)
        {
            startGame(room, roomId);
            return;
        }

        emit AddPlayerToRoom(roomId, room.playerWalletList.length);
    }
    //=============================================================================
    function    isRoomOpen(uint roomId) external view returns(bool)
    {
        require(roomId<rooms.length,   "Bad Id for room");

        TRoom memory room = rooms[roomId - 1];

        if (room.isEternal)     return true;        // YES it's open

        return (block.timestamp>=room.startDate && block.timestamp<=room.endDate);
    }
    //=============================================================================
    function    changeRoomDates(uint roomId, bool isNowEternal, uint start, uint end) external onlyAdminOrOwner
    {
        require(roomId<rooms.length,   "Bad Id for room");

        TRoom storage room = rooms[roomId - 1];

        if (start>end)
        {
            uint v = start;
            start  = end;
            end    = v;
        }

        emit ChangeRoomDates(roomId, room.isEternal, room.startDate, room.endDate, isNowEternal, start, end);

        room.isEternal = isNowEternal;
        room.startDate = start;
        room.endDate   = end;
    }
    //=============================================================================
    function    startGame(TRoom storage room, uint roomId) internal
    {
        require(room.playerWalletList.length==room.maxPlayerCount,  "Invalid players count in room");

        randomNonce++;

        room.loserId = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, randomNonce))) % room.maxPlayerCount;

        uint roomFee        = (roomFeePercentInM100 * room.entryPriceInWei) / (100*100);
        uint perWinnerGain  = (room.balanceInWei - roomFee) / (room.maxPlayerCount-1);

        uint withdrawAmount = room.balanceInWei;

        room.gainPerWinnerInWei = perWinnerGain - room.entryPriceInWei;
        room.feeInWei           = roomFee;

        bool sent = false;

        TDraw[] storage roomDraws = draws[roomId];

        for (uint i; i<room.maxPlayerCount; i++)
        {
            if (i==room.loserId)                continue;       // This guy has LOST
            if (withdrawAmount<perWinnerGain)   break;
            
            (sent,) = room.playerWalletList[i].call{value: perWinnerGain}("");    //require(sent, "Failed sending commission");

            withdrawAmount -= perWinnerGain;

            TDraw memory draw = TDraw(
            {
                roomId              :   roomId,
                wallet              :   room.playerWalletList[i],
                entryPriceInWei     :   room.entryPriceInWei,
                gainPerWinnerInWei  :   perWinnerGain,
                playedDate          :   block.timestamp
            });

            roomDraws.push(draw);
        }

        dispatchFees(withdrawAmount);

        //-----

        address[] memory  walletList;

        room.playerWalletList = walletList;         // on part avec une liste fraiche
        room.balanceInWei     = 0;

        //-----

        emit GamePlayedInRoom(roomId, room.playerWalletList.length, room.entryPriceInWei, perWinnerGain, withdrawAmount, room);       // withdrawAmount = roomFee (what's left is for the service)
    }
    //=============================================================================
    function    unsubcribePlayer(uint roomId) external
    {
        bool    isFound = false;

        require(roomId < rooms.length, "Invalid room ID");

        TRoom storage room = rooms[roomId - 1];

        for(uint i; i<room.playerWalletList.length; i++)
        {
            if (room.playerWalletList[i]!=msg.sender)   continue;

            isFound = true;

            delete room.playerWalletList[i];

            if (room.balanceInWei>=room.entryPriceInWei)
            {
                room.balanceInWei -= room.entryPriceInWei;
            }
            break;
        }

        require(isFound==true, "You are not in this room");

        emit UnsubcribePlayer(roomId, msg.sender, room.playerWalletList.length, room.entryPriceInWei, room.balanceInWei);
    }
    //=============================================================================
    //=============================================================================
    function    setAdmin(address newAdmin) external onlyOwner
    {
        require(newAdmin!=address(0x0) && newAdmin!=admin, "Invalid address");

        admin = newAdmin;
    }
    //=============================================================================
    //=============================================================================
    function    setCollaborators(address[] memory TheWallets, 
                                  string[] memory TheCollaboratorNames, 
                                    uint[] memory TheSharePercentsInM100)  
                    external onlyOwner
    {
        require(msg.sender==owner,                      "Not owner");
        require(totalCollaboratorsSharePercent!=10000,  "Collaborators already listed");
        
        uint nWallet = TheWallets.length;
        uint nShares = TheSharePercentsInM100.length;
        
        require(nWallet==nShares, "Wallets & percents array not same size");
        
        for(uint i=0; i<nWallet; i++)
        {
            collaborators.push( TCollaborator( TheWallets[i], TheCollaboratorNames[i], TheSharePercentsInM100[i] ));
            
            collaboratorNames[ TheWallets[i] ] = TheCollaboratorNames[i];
        
            totalCollaboratorsSharePercent += TheSharePercentsInM100[i];
        }

        require(totalCollaboratorsSharePercent==10000, "Invalid collaborators share%");
    }
    //=============================================================================
    function    changeCollaboratorWallet(address newWallet) external
    {
        bool        isKnownWallet = false;

        for (uint i; i<collaborators.length; i++) 
        {
            if (collaborators[i].wallet==newWallet)
            {
                isKnownWallet = true;
                break;
            }
        }

        require(isKnownWallet==false, "New wallet already used");

        for (uint i; i<collaborators.length; i++) 
        {
            if (collaborators[i].wallet==msg.sender)
            {
                collaborators[i].wallet        = newWallet;
                collaboratorNames[ newWallet ] = collaboratorNames[ msg.sender];
                break;
            }
        }

        emit ChangeCollaboratorWallet(msg.sender, newWallet);
    }
    //=============================================================================
    function    calculateCollaboratorShare(uint x,uint y) internal pure returns (uint) 
    {
        uint a = x / 10000;
        uint b = x % 10000;
        uint c = y / 10000;
        uint d = y % 10000;

        return a * c * 10000 + a * d + b * c + (b * d) / 10000;
    }
    //=============================================================================
    function    dispatchFees(uint totalFeeAmountToShare) internal
    {
        if (totalFeeAmountToShare==0)   return;     // There is no or no-more fee to play, right now
       
        uint nCollaborator  = collaborators.length;
        uint totalSent      = 0;
        uint dividendAmount = 0;

        for (uint i; i<nCollaborator; i++) 
        {
            address collaboratorWallet = collaborators[i].wallet;
            
            if (i<(nCollaborator-1))    dividendAmount = calculateCollaboratorShare(totalFeeAmountToShare, collaborators[i].shareInM100);
            else                        dividendAmount = totalFeeAmountToShare - totalSent;     // Gerer les decimales residuelles

            (bool sent,) = collaboratorWallet.call{value: dividendAmount}("");    require(sent, "Failed sending commission");

            totalSent += dividendAmount;
        }

        //-----

        overallFee += totalSent;

        TFee memory feeObj = TFee
        (
            block.timestamp,
            totalSent
        );

        fees.push(feeObj);

        emit FeeDispatch(totalSent, feeObj);
    }
    //=============================================================================
    //=============================================================================
    //=============================================================================
    function    getLatestDraws(uint count) external view returns(TRoom[] memory)
    {
        require(count>0, "At least set one draw");

        uint nFound = 0;

        TRoom[] memory lastPlayedRooms = new TRoom[](count);

        for (uint i; i<rooms.length; i++)
        {
            TRoom memory room = rooms[i];

            lastPlayedRooms[nFound] = room;
            
            nFound++;
            if (nFound>=count)      break;
        }

        if (nFound!=count)              // Ya moins de resultats que prevu, on delete les indésirables
        {
            uint nDel = count - nFound;
            for(uint i; i<nDel; i++)
            {
                delete lastPlayedRooms[ lastPlayedRooms.length ];
            }
        }

        return lastPlayedRooms;
    }
    //=============================================================================
    function    getRoomCount() external view returns(uint)
    {
        return rooms.length;
    }
    //=============================================================================
    function    getRoom(uint id) external view returns(TRoom memory)
    {
        require(id <= rooms.length,     "Invalid ID");

        return rooms[id];
    }
    //=============================================================================
    function    getRoomByName(string memory roomName) external view returns(TRoom memory)
    {
        require(roomNames[roomName]!=0, "Unknown room");

        uint roomId = roomNames[roomName]-1;

        require(roomId <= rooms.length,     "Invalid ID");

        return rooms[roomId];
    }
    //=============================================================================
    function    getRooms(uint from, uint to) external view returns(TRoom[] memory)
    {
        require(from < rooms.length,    "Bad FROM");
        require(  to < rooms.length,    "Bad TO");

        if (from > to)
        {
            uint v = from;
              from = to;
                to = v;
        }

        //-----

        uint nToExtract = (to - from) + 1;

        TRoom[] memory foundRooms = new TRoom[](nToExtract);

        uint g = 0;

        for (uint id=from; id<=to; id++) 
        {
            foundRooms[g] = rooms[id];
            g++;
        }

        return foundRooms;
    }
    //=============================================================================
    //=============================================================================
}