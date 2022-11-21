// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "DataTransfer.sol";

contract ContractA {
    // this is a comment
    address owner;
    mapping(address => string[]) addrToProperties;
    mapping(string => address) propToAddr;
    mapping(string => uint256) salePrice;
    mapping(string => uint256) mintPrice;
    mapping(string => uint256) status;
    mapping(string => bool) propInList;
    mapping(address => uint256) coinBalance;
    mapping(address => uint256) userMintValue;
    mapping(address => uint256) lastClaimTime;
    string[] allProps;
    address[] owners;
    address[] players;
    uint256 power = 8;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner.");
        _;
    }

    function allocateFunds(uint256 amount, address receiver)
        public
        payable
        onlyOwner
    {
        (bool sent, bytes memory data) = receiver.call{value: amount}(""); /*, bytes memory data*/
        require(sent, "Fund allocation failed.");
    }

    function privateFundTransfer(uint256 amount, address receiver) private {
        (bool sent, bytes memory data) = receiver.call{value: amount}("");
        require(sent, "Fund allocation failed.");
    }

    function addPlayer(address _player) private {
        uint256 length = players.length;
        bool inList = false;
        for (uint256 i = 0; i < length; ++i) {
            if (players[i] == _player) {
                inList = true;
            }
        }
        if (!inList) {
            players.push(_player);
        }
    }

    function propsToChain(string[] memory _props, uint256[] memory _mintPrices)
        public
        onlyOwner
    {
        uint256 length = _props.length;
        for (uint256 i = 0; i < length; ++i) {
            if (propInList[_props[i]] == false) {
                allProps.push(_props[i]);
                owners.push(address(0));
                salePrice[_props[i]] = 0;
                mintPrice[_props[i]] = _mintPrices[i] * 10000000000000000;
                status[_props[i]] = 0;
                propInList[_props[i]] = true;
            }
        }
    }

    function coinMintProperty(string memory _prop) public {
        require(status[_prop] == 0, "This property is already minted.");
        require(
            coinBalance[msg.sender] >= mintPrice[_prop],
            "You don't have enough coins!"
        );
        addPlayer(msg.sender);

        if (lastClaimTime[msg.sender] == 0) {
            lastClaimTime[msg.sender] = block.timestamp;
        }

        status[_prop] = 1;
        coinBalance[msg.sender] -= mintPrice[_prop];
        uint256 length = allProps.length;
        for (uint256 i = 0; i < length; ++i) {
            if (equal(allProps[i], _prop)) {
                owners[i] = msg.sender;
            }
        }
        addrToProperties[msg.sender].push(_prop);
        propToAddr[_prop] = msg.sender;

        privateClaimCoins(msg.sender);
        userMintValue[msg.sender] += mintPrice[_prop];
    }

    function devCoins() public onlyOwner {
        coinBalance[msg.sender] += (10**17) * 5;
    }

    function sendCoins(address receiver, uint256 amount) public {
        uint256 actualAmount = amount * (10**15);
        require(coinBalance[msg.sender] >= actualAmount);
        coinBalance[msg.sender] -= actualAmount;
        coinBalance[receiver] += actualAmount;
    }

    function mintProperty(string memory _prop) public payable {
        require(status[_prop] == 0, "This property is already minted.");
        //require(salePrice[_prop] == -1, "This property is already minted.");
        require(
            mintPrice[_prop] == msg.value,
            "You must pay the exact mint price."
        );
        //salePrice[_prop] = -2;
        addPlayer(msg.sender);

        if (lastClaimTime[msg.sender] < 1) {
            lastClaimTime[msg.sender] = block.timestamp;
        }

        status[_prop] = 1;
        uint256 length = allProps.length;
        for (uint256 i = 0; i < length; ++i) {
            if (equal(allProps[i], _prop)) {
                owners[i] = msg.sender;
            }
        }
        addrToProperties[msg.sender].push(_prop);
        propToAddr[_prop] = msg.sender;

        privateClaimCoins(msg.sender);

        userMintValue[msg.sender] += mintPrice[_prop];
    }

    function getLastClaimTime() public view returns (uint256) {
        return lastClaimTime[msg.sender];
    }

    function getClaimableAmount() public view returns (uint256) {
        uint256 claimTime;

        if (lastClaimTime[msg.sender] != 0) {
            claimTime = block.timestamp - lastClaimTime[msg.sender];
            uint256 addedBalance = (claimTime * userMintValue[msg.sender]) /
                (10**power); //15
            // if (addedBalance < 1) {
            //     return;
            // }
            return addedBalance;
        }
        return 0;
    }

    function getYieldPerBlock() public view returns (uint256) {
        uint256 yield = (1 * userMintValue[msg.sender]) / (10**power);
        return yield;
    }

    function claimCoins() public {
        uint256 claimTime;
        if (lastClaimTime[msg.sender] == 0) {
            lastClaimTime[msg.sender] = block.timestamp;
            //return;
        }
        if (lastClaimTime[msg.sender] != 0) {
            claimTime = block.timestamp - lastClaimTime[msg.sender];
            uint256 addedBalance = (claimTime * userMintValue[msg.sender]) /
                (10**power); //15
            if (addedBalance < 1) {
                return;
            }
            lastClaimTime[msg.sender] = block.timestamp;
            coinBalance[msg.sender] += addedBalance;
        }
        //uint256 claimableAmount =
    }

    function privateClaimCoins(address claimer) private {
        uint256 claimTime;
        if (lastClaimTime[claimer] == 0) {
            lastClaimTime[claimer] = block.timestamp;
            //return;
        }
        if (lastClaimTime[claimer] != 0) {
            claimTime = block.timestamp - lastClaimTime[claimer];
            lastClaimTime[claimer] = block.timestamp;
            coinBalance[claimer] +=
                (claimTime * userMintValue[claimer]) /
                (10**power);
        }
        //uint256 claimableAmount =
    }

    function buyFromUser(string memory _prop, address seller) public payable {
        require(
            status[_prop] == 2,
            "This property is not listed for sale by any users."
        );
        //require(salePrice[_prop] == -1, "This property is already minted.");
        require(
            salePrice[_prop] == msg.value,
            "You must pay the exact sale price."
        );
        //salePrice[_prop] = -2;

        addPlayer(msg.sender);

        if (lastClaimTime[msg.sender] == 0) {
            lastClaimTime[msg.sender] = block.timestamp;
        }

        privateFundTransfer((msg.value / 100) * 99, seller);
        status[_prop] = 1;
        uint256 length = allProps.length;
        for (uint256 i = 0; i < length; ++i) {
            if (equal(allProps[i], _prop)) {
                owners[i] = msg.sender;
                privateClaimCoins(seller);
                privateClaimCoins(msg.sender);
                userMintValue[msg.sender] += mintPrice[_prop];
                userMintValue[seller] -= mintPrice[_prop];
            }
        }

        //addrToProperties[seller]
        //addrToProperties[msg.sender].push(_prop);
        //propToAddr[_prop] = msg.sender;
    }

    function sellProperty(string memory _prop, uint256 _salePrice) public {
        uint256 length = allProps.length;
        address propOwner;
        for (uint256 i = 0; i < length; ++i) {
            if (equal(allProps[i], _prop)) {
                propOwner = owners[i];
            }
        }
        require(
            propOwner == msg.sender,
            "You are not the owner of this property."
        );
        require(status[_prop] != 2, "This property is already for sale.");
        //require(propToAddr[_prop] == msg.sender, "You do not own this property.");
        require(_salePrice > 10**14, "Sale price must be higher than 0.0001");
        status[_prop] = 2;
        salePrice[_prop] = _salePrice;
    }

    function removeFromSale(string memory _prop) public {
        uint256 length = allProps.length;
        address propOwner;
        for (uint256 i = 0; i < length; ++i) {
            if (equal(allProps[i], _prop)) {
                propOwner = owners[i];
            }
        }
        require(
            propOwner == msg.sender,
            "You are not the owner of this property."
        );
        require(status[_prop] == 2, "This property is not for sale.");
        status[_prop] = 1;
    }

    function getBalancesList() public view returns (uint256[] memory) {
        uint256 length = players.length;
        uint256[] memory balances = new uint256[](length);
        for (uint256 i = 0; i < length; ++i) {
            balances[i] = coinBalance[players[i]];
        }
        return balances;
    }

    function getLastClaimTimesList() public view returns (uint256[] memory) {
        uint256 length = players.length;
        uint256[] memory lastClaimTimes = new uint256[](length);
        for (uint256 i = 0; i < length; ++i) {
            lastClaimTimes[i] = lastClaimTime[players[i]];
        }
        return lastClaimTimes;
    }

    function getUserMintValuesList() public view returns (uint256[] memory) {
        uint256 length = players.length;
        uint256[] memory userMintValues = new uint256[](length);
        for (uint256 i = 0; i < length; ++i) {
            userMintValues[i] = userMintValue[players[i]];
        }
        return userMintValues;
    }

    function getStatusesList() public view returns (uint256[] memory) {
        uint256 length = allProps.length;
        uint256[] memory propStatuses = new uint256[](length);
        for (uint256 i = 0; i < length; ++i) {
            propStatuses[i] = status[allProps[i]];
        }
        return propStatuses;
    }

    function exportData()
        public
        returns (
            address[] memory _owners,
            address[] memory _players,
            uint256[] memory _balances,
            uint256[] memory _lastClaimTimes
        )
    {
        _owners = owners;
        _players = players;
        _balances = getBalancesList();
        _lastClaimTimes = getLastClaimTimesList();
        return (_owners, _players, _balances, _lastClaimTimes);
    }

    function exportOwners() public view returns (address[] memory) {
        return owners;
    }

    function exportPlayers() public view returns (address[] memory) {
        return players;
    }

    function exportBalances() public view returns (uint256[] memory) {
        return getBalancesList();
    }

    function exportLastClaimTimes() public returns (uint256[] memory) {
        return getLastClaimTimesList();
    }

    function exportUserMintValues() public returns (uint256[] memory) {
        return getUserMintValuesList();
    }

    function exportStatuses() public returns (uint256[] memory) {
        return getStatusesList();
    }

    function getData(address payable addressOfDT) public onlyOwner {
        DataTransfer my_dt = DataTransfer(addressOfDT);
        owners = my_dt.exportOwners();
        players = my_dt.exportPlayers();

        uint256 length = players.length;
        uint256[] memory balances = my_dt.exportBalances();
        uint256[] memory lastClaimTimes = my_dt.exportLastClaimTimes();
        uint256[] memory userMintValues = my_dt.exportUserMintValues();
        for (uint256 i = 0; i < length; ++i) {
            coinBalance[players[i]] = balances[i];
            lastClaimTime[players[i]] = lastClaimTimes[i];
            userMintValue[players[i]] = userMintValues[i];
        }
        uint256 propLength = allProps.length;
        uint256[] memory propStatuses = my_dt.exportStatuses();
        for (uint256 i = 0; i < propLength; ++i) {
            status[allProps[i]] = propStatuses[i];
        }
    }

    // function importData(
    //     address[] memory _owners,
    //     address[] memory _players,
    //     uint256[] memory _balances,
    //     uint256[] memory _lastClaimTimes
    // ) public onlyOwner {
    //     owners = _owners;
    //     for (uint256 i = 0; i < _players.length; ++i) {
    //         coinBalance[_players[i]] = _balances[i];
    //         lastClaimTime[_players[i]] = _lastClaimTimes[i];
    //     }
    // }

    function getCoinBalance() public view returns (uint256) {
        return coinBalance[msg.sender];
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getMyProperties() public view returns (string[] memory) {
        uint256 length = owners.length;
        uint256 index = 0;
        for (uint256 i = 0; i < length; ++i) {
            if (owners[i] == msg.sender) {
                index++;
            }
        }
        string[] memory myProperties = new string[](index);
        uint256 ind = 0;
        for (uint256 i = 0; i < length; i++) {
            if (owners[i] == msg.sender) {
                myProperties[ind] = allProps[i];
                ind++;
            }
        }
        return myProperties;
    }

    function getAllProperties() public view returns (string[] memory) {
        return allProps;
    }

    function getAllStatuses() public view returns (uint256[] memory) {
        uint256 length = allProps.length;
        uint256[] memory statuses = new uint[](length);
        for (uint256 i = 0; i < length; i++) {
            string memory currentProperty = allProps[i];
            uint256 currentStatus = status[currentProperty];
            statuses[i] = currentStatus;
        }
        return statuses;
    }

    function getAllOwners() public view returns (address[] memory) {
        return owners;
    }

    function getAllSalePrices() public view returns (uint256[] memory) {
        uint256 length = allProps.length;
        uint256[] memory salePrices = new uint[](length);
        for (uint256 i = 0; i < length; i++) {
            string memory currentProperty = allProps[i];
            uint256 currentSalePrice = salePrice[currentProperty];
            salePrices[i] = currentSalePrice;
        }
        return salePrices;
    }

    function getUserMintValue() public view returns (uint256) {
        return userMintValue[msg.sender];
    }

    function getStatus(string memory _prop) public view returns (uint256) {
        return status[_prop];
    }

    function getSalePrice(string memory _prop) public view returns (uint256) {
        return salePrice[_prop];
    }

    function getMintPrice(string memory _prop) public view returns (uint256) {
        return mintPrice[_prop];
    }

    receive() external payable {}

    function compare(string memory _a, string memory _b)
        private
        pure
        returns (int)
    {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        for (uint i = 0; i < minLength; i++)
            if (a[i] < b[i]) return -1;
            else if (a[i] > b[i]) return 1;
        if (a.length < b.length) return -1;
        else if (a.length > b.length) return 1;
        else return 0;
    }

    function equal(string memory _a, string memory _b)
        private
        pure
        returns (bool)
    {
        return compare(_a, _b) == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "ContractA.sol";

contract DataTransfer {
    address[] public owners;
    address[] public players;
    uint256[] public balances;
    uint256[] public lastClaimTimes;
    uint256[] public userMintValues;
    uint256[] public statuses;
    ContractA ca;

    constructor() {
        ca = new ContractA();
    }

    function exportOwners() public view returns (address[] memory) {
        return owners;
    }

    function exportPlayers() public view returns (address[] memory) {
        return players;
    }

    function exportBalances() public view returns (uint256[] memory) {
        return balances;
    }

    function exportLastClaimTimes() public view returns (uint256[] memory) {
        return lastClaimTimes;
    }

    function exportUserMintValues() public view returns (uint256[] memory) {
        return userMintValues;
    }

    function exportStatuses() public returns (uint256[] memory) {
        return statuses;
    }

    function importData() public {
        (owners, players, balances, lastClaimTimes) = ca.exportData();
        //return ca.getTestNumber();
        //address(0x358AA13c52544ECCEF6B0ADD0f801012ADAD5eE3).call(bytes memory(keccak256("exportData()")));
    }

    function getData(address payable addressOfA) public {
        ContractA my_a = ContractA(addressOfA);
        //owners, players, balances, lastClaimTimes = my_a.exportData();
        owners = my_a.exportOwners();
        players = my_a.exportPlayers();
        balances = my_a.exportBalances();
        lastClaimTimes = my_a.exportLastClaimTimes();
        userMintValues = my_a.exportUserMintValues();
        statuses = my_a.exportStatuses();
    }

    // function doYourThing(address payable addressOfA)
    //     public
    //     view
    //     returns (address[] memory)
    // {
    //     ContractA my_a = ContractA(addressOfA);
    //     return my_a.getAllOwners();
    // }
}