/**
 *Submitted for verification at polygonscan.com on 2023-01-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

struct  TRoom
{
    uint        id;
    uint        balance;
    uint        entryPrice;
    uint        loserId;
    uint        maxPlayerCount;
    string      name;
    uint        createdDate;
    uint        playedDate;
    uint        gainPerWinner;
    uint        fee;
    bool        isEternal;
    uint[]      openDates;
    address[]   playerWalletList;
    address[]   winnerWalletList;
}

struct  TCollaborator 
{
    address     wallet;
    uint        shareInM100;
}

struct  TFee
{
    uint        amount;
    uint        date;
}

struct  TDraw
{
    uint        roomId;
    address     wallet;
    uint        entryPrice;
    uint        gainPerWinner;
    uint        playedDate;
}

struct  TPlayerStat
{
    uint        gameWonCount;
    uint        gameLostCount;
    uint        gamePlayedCount;
    uint        totalBet;
    uint        totalGain;
    uint        totalLoss;
}
//------------------------------------------------------------------------------
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
//------------------------------------------------------------------------------
contract    RuskoffKill     is ReentrancyGuard
{
    modifier    onlyOwner()         { require(msg.sender==owner);                       _; }
    modifier    onlyAdminOrOwner    { require(msg.sender==owner || msg.sender==admin);  _; }

    TRoom[]                                 rooms;
    mapping(string=>uint)           private roomNames;

    uint                            public  roomFeePercentInM100 = 5  *100;     // 5% commission

    uint                            private totalCollaboratorsSharePercent = 0;
    TCollaborator[]                 private collaborators;

    address                         public  owner;
    address                         private admin;

    TFee[]                          private fees;
    uint                            private overallFee;

    uint                            private randomNonce;

    mapping(address=>TPlayerStat)   private playersStats;

    mapping(uint => TDraw[])        private draws;

    uint                            private maxListablePlayerCount = 50;

    constructor()
    {
        owner = msg.sender;
        admin = msg.sender;

        randomNonce = block.timestamp * block.number;
    }

    event   CreateRoom(uint roomId, uint maxPlayerCount, uint entryPrice, string name, bool isEternal, uint[] openDates);
    event   CloseRoom(uint roomId);
    event   ChangeRoomDates(uint roomId, bool isEternal, uint[] openDates);
    event   ChangeRoomEntryPrice(uint roomId, uint newPrice);
    event   FeeDispatch(uint amount, TFee feeObj);
    event   AddPlayerToRoom( uint roomId, uint playerCount); 
    event   GamePlayedInRoom(uint roomId, uint playerCount, uint entryPrice, uint perWinnerGain, uint roomFee, bool hasWon, TRoom room); 
    event   UnsubcribePlayer(uint roomId, address playerWallet, uint remainingPlayerCount, uint entryPrice, uint roomBalance);
    event   ChangeCollaboratorWallet(address previousWallet, address newWallet);
    event   SetFee(uint previousFee, uint newFee);

    //==========================================================================
    //==========================================================================
    function    createRoom( uint            maxPlayerCount, 
                            uint            entryPrice, 
                            string memory   name,
                            bool            isEternal,
                            uint[] memory   dates)
                    external 
                    onlyAdminOrOwner
                    returns(uint)
    {
        require(roomNames[name]==0,                 "Room name exists");
        require(maxPlayerCount>1,                   "Two players at least");

        //----- check if viable room

        uint roomFee        = (roomFeePercentInM100 * entryPrice * maxPlayerCount) / (100*100);
        uint perWinnerGain  = ((entryPrice * maxPlayerCount) - roomFee) / (maxPlayerCount-1);

        require(perWinnerGain > entryPrice,    "entryPrice seems to LOW");

        //-----

        address[] memory  walletList;

        TRoom memory room = TRoom
        ({
            id                  :   rooms.length,
            entryPrice          :   entryPrice,
            balance             :   0,
            loserId             :   0,
            maxPlayerCount      :   maxPlayerCount,
            name                :   name,
            createdDate         :   block.timestamp,
            playedDate          :   0,
            gainPerWinner       :   perWinnerGain,
            fee                 :   roomFee,
            isEternal           :   isEternal,
            openDates           :   dates,
            playerWalletList    :   walletList,
            winnerWalletList    :   walletList
        });

        rooms.push(room);

        roomNames[name] = rooms.length;     // sauve l'ID+1

        emit CreateRoom(rooms.length-1 /*ID*/ , maxPlayerCount, entryPrice, name, isEternal, dates);

        return rooms.length;
    }
    //==========================================================================
    function    closeRoom(uint id)  external     onlyAdminOrOwner
    {
        require(id < rooms.length,      "Invalid ID");
        
        TRoom storage room = rooms[id];

        for(uint i; i<room.playerWalletList.length; i++)        // Refund all participants
        {
            (bool sent,) = room.playerWalletList[i].call{value: room.entryPrice}("");    require(sent, "Failed sending back bet amount");
        }

        address[] memory  walletList;

        room.playerWalletList = walletList;         // on part avec une liste fraiche = SANS RIEN DEDANS

        emit CloseRoom(id);
    }
    //==========================================================================
    function    addPlayerToRoom(uint roomId) external payable   nonReentrant
    {
        require(roomId<rooms.length,   "Bad Id for room");

        TRoom storage room = rooms[roomId];

        if (room.isEternal==false)          // date specifiques, verifions que c'est bien ouvert maintenant
        {
            bool isOpen = false;
            uint nDate  = room.openDates.length & 0xfffffe;
            for(uint i=0; i<nDate; i+=2)
            {
                if (room.openDates[i]<block.timestamp)      continue;   // avant 
                if (room.openDates[i+1]>block.timestamp)    continue;   // apres

                isOpen=true;
                break;
            }
            
            require(isOpen==true, "The room is currently closed");
        }

        require(msg.value==room.entryPrice,    "Entry price invalid");

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
        room.balance += room.entryPrice;

        if (room.playerWalletList.length==room.maxPlayerCount)
        {
            startGame(room, roomId);
            return;
        }

        emit AddPlayerToRoom(roomId, room.playerWalletList.length);
    }
    //==========================================================================
    function    isRoomOpen(uint roomId) external view returns(bool)
    {
        require(roomId<rooms.length,   "Bad Id for room");

        TRoom memory room = rooms[roomId];

        if (room.isEternal)     return true;        // YES it's open

        uint nDate = room.openDates.length & 0xfffffe;
        
        for(uint i=0; i<nDate; i+=2)
        {
            if (room.openDates[i]<block.timestamp)      continue;   // avant 
            if (room.openDates[i+1]>block.timestamp)    continue;   // apres

            return true;
        }
        return false;
    }
    //==========================================================================
    function    changeRoomDates(uint roomId, bool isNowEternal, uint[] memory dates) external onlyAdminOrOwner
    {
        require(roomId<rooms.length,   "Bad Id for room");

        TRoom storage room = rooms[roomId];

        room.isEternal = isNowEternal;
        room.openDates = dates;

        emit ChangeRoomDates(roomId, isNowEternal, dates);
    }
    //==========================================================================
    function    changeRoomEntryPrice(uint roomId, uint newPrice) external onlyAdminOrOwner
    {
        require(newPrice!=0, "Invalid price");

        TRoom storage room = rooms[roomId];

        room.entryPrice = newPrice;

        emit ChangeRoomEntryPrice(roomId, newPrice);
    }
    //==========================================================================
    function    startGame(TRoom storage room, uint roomId) internal
    {
        require(room.playerWalletList.length==room.maxPlayerCount,  "Invalid players count in room");

        randomNonce++;

        room.loserId = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, randomNonce))) % room.maxPlayerCount;

        uint amountToWithdraw = room.balance;

        address loserWallet = address(0x0);
        bool    sent        = false;

        TDraw[] storage roomDraws = draws[roomId];

        for (uint i; i<room.maxPlayerCount; i++)
        {
            address             wallet = room.playerWalletList[i];
            TPlayerStat storage player = playersStats[wallet];

            player.gamePlayedCount++;
            player.totalBet += room.entryPrice;

            if (i==room.loserId)                
            {
                loserWallet = wallet;
                player.gameLostCount++;
                player.totalLoss += room.entryPrice;
                continue;           // This guy has LOST
            }

            //----- ajouter un gagnant cycliquement

            if (room.winnerWalletList.length>=maxListablePlayerCount)
            {
                delete room.winnerWalletList[0];        // supprimer le + ancien des gagnants
            }

            room.winnerWalletList.push(wallet);         // un autre gagnant

            //-----

            player.totalGain += room.gainPerWinner;
            player.gameWonCount++;

            if (amountToWithdraw < room.gainPerWinner)   break;
            
            (sent,) = wallet.call{value: room.gainPerWinner}("");    //require(sent, "Failed sending commission");

            amountToWithdraw -= room.gainPerWinner;

            TDraw memory draw = TDraw(
            {
                roomId          :   roomId,
                wallet          :   wallet,
                entryPrice      :   room.entryPrice,
                gainPerWinner   :   room.gainPerWinner,
                playedDate      :   block.timestamp
            });

            roomDraws.push(draw);
        }

        dispatchFees(amountToWithdraw);

        //-----

        address[] memory  walletList;

        room.playerWalletList = walletList;         // on part avec une liste fraiche
        room.balance     = 0;

        //-----

        emit GamePlayedInRoom(roomId, room.playerWalletList.length, room.entryPrice,
                              room.gainPerWinner, amountToWithdraw,
                              (msg.sender!=loserWallet),
                              room);       // withdrawAmount = roomFee (what's left is for the service)
    }
    //==========================================================================
    function    unsubcribePlayer(uint roomId) external
    {
        bool    isFound = false;

        require(roomId < rooms.length, "Invalid room ID");

        TRoom storage room = rooms[roomId];

        for(uint i; i<room.playerWalletList.length; i++)
        {
            if (room.playerWalletList[i]!=msg.sender)   continue;

            isFound = true;

            delete room.playerWalletList[i];

            if (room.balance>=room.entryPrice)
            {
                room.balance -= room.entryPrice;
            }
            break;
        }

        require(isFound==true, "You are not in this room");

        emit UnsubcribePlayer(roomId, msg.sender, room.playerWalletList.length, room.entryPrice, room.balance);
    }
    //==========================================================================
    function    getPlayerStats(address guy) external view returns(TPlayerStat memory)
    {
        return playersStats[guy];           // cumul de gain de ce joueur
    }
    //==========================================================================
    //==========================================================================
    function    setAdmin(address newAdmin) external onlyOwner
    {
        require(newAdmin!=address(0x0) && newAdmin!=admin, "Invalid address");

        admin = newAdmin;
    }
    //==========================================================================
    //==========================================================================
    function    setCollaborators(address[] memory TheWallets,
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
            collaborators.push( TCollaborator( TheWallets[i], TheSharePercentsInM100[i] ));
            
            totalCollaboratorsSharePercent += TheSharePercentsInM100[i];
        }

        require(totalCollaboratorsSharePercent==10000, "Invalid collaborators share%");
    }
    //==========================================================================
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
                collaborators[i].wallet = newWallet;
                break;
            }
        }

        emit ChangeCollaboratorWallet(msg.sender, newWallet);
    }
    //==========================================================================
    function    calculateCollaboratorShare(uint x,uint y) internal pure returns (uint) 
    {
        uint a = x / 10000;
        uint b = x % 10000;
        uint c = y / 10000;
        uint d = y % 10000;

        return a * c * 10000 + a * d + b * c + (b * d) / 10000;
    }
    //==========================================================================
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
    //==========================================================================
    //==========================================================================
    //==========================================================================
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
    //==========================================================================
    function    getRoomCount() external view returns(uint)
    {
        return rooms.length;
    }
    //==========================================================================
    function    getRoom(uint id) external view returns(TRoom memory)
    {
        require(id <= rooms.length,     "Invalid ID");

        return rooms[id];
    }
    //==========================================================================
    function    getRoomByName(string memory roomName) external view returns(TRoom memory)
    {
        require(roomNames[roomName]!=0, "Unknown room");

        uint roomId = roomNames[roomName]-1;

        require(roomId <= rooms.length,     "Invalid ID");

        return rooms[roomId];
    }
    //==========================================================================
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
    //==========================================================================
    function    setFee(uint newFee) external
    {
        require(newFee<50*100, "Fee% to high");

        uint oldFee          = roomFeePercentInM100;
        roomFeePercentInM100 = newFee;

        emit SetFee(oldFee, newFee);
    }
    //==========================================================================
}