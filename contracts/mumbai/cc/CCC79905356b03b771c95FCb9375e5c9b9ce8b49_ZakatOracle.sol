/**
 *Submitted for verification at polygonscan.com on 2022-11-27
*/

// File: contracts/Context.sol

pragma solidity 0.6.6;

contract Context {
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

// File: contracts/BasicAccessControl.sol

pragma solidity 0.6.6;

contract BasicAccessControl is Context {
    address payable public owner;
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping(address => bool) public moderators;
    bool public isMaintaining = false;

    constructor() public {
        owner = msgSender();
    }

    modifier onlyOwner() {
        require(msgSender() == owner);
        _;
    }

    modifier onlyModerators() {
        require(msgSender() == owner || moderators[msgSender()] == true);
        _;
    }

    modifier isActive() {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address payable _newOwner) public onlyOwner {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }

    function AddModerator(address _newModerator) public onlyOwner {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        }
    }

    function Kill() public onlyOwner {
        selfdestruct(owner);
    }
}

// File: contracts/ZakatOracle.sol

pragma solidity 0.6.6;

contract ZakatOracle is BasicAccessControl {
    uint256 zktsInEth = 0;
    // ZKT price per dollar
    uint256 public zktPrice = 0;
    // ETH price per dollar
    uint256 public ethPrice = 0;

    uint256 zktCap = 0;
    uint256 ethCap = 0;
    uint256 zktMaxCap = 0;
    uint256 ethMaxCap = 0;

    constructor() public {
        ethMaxCap = 1 * 10**18;
        zktMaxCap = 1 * 10**18;
    }

    /**
        @param _amount: uint256 => Amount in ETH 
        @return Price in ZKT
        Disctiption: Pass 1 ETH get value in ZKT
    */
    function getZktRatesFromEth(uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint256 ethP = ethPrice * _amount;
        uint256 zktP = zktPrice * 10**18;

        uint256 rate = ethP / zktP;
        if (rate <= 0) {
            rate = (ethP * 10**18) / zktP;
            rate = (rate < ethCap) ? ethCap : rate;
            return rate;
        }
        rate = rate * 10**18;
        rate = (rate < ethCap) ? ethCap : rate;

        return rate;
    }

    /**
        @param _amount: uint256 => Amount in ZKT 
        @return Price in ETH
        Disctiption: Pass 1 ZKT get value in ETH
    */
    function getEthRatesFromZkt(uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint256 zktP = zktPrice * _amount;
        uint256 ethP = ethPrice * 10**18;

        uint256 rate = zktP / ethP;
        if (rate <= 0) {
            rate = (zktP * 10**18) / ethP;
            rate = (rate < zktCap) ? zktCap : rate;
            return rate;
        }
        rate = (rate < zktCap) ? zktCap : rate;

        return rate;
    }

    function updatePrices(uint256 _zktPrice, uint256 _ethPrice)
        external
        onlyModerators
    {
        if (_zktPrice < zktCap) zktPrice = _zktPrice;
        if (_ethPrice < ethCap) ethPrice = _ethPrice;

        ethPrice = _ethPrice;
        zktPrice = _zktPrice;
    }

    function setCapZkt(uint256 _zktCap) external onlyModerators {
        require(_zktCap < zktMaxCap, "Cannot put cap lesser than 0");
        zktCap = _zktCap;
    }

    function setCapEth(uint256 _ethCap) external onlyModerators {
        require(_ethCap <= ethMaxCap, "Cannot put cap lesser than 0");
        ethCap = _ethCap;
    }

    function setMaxCapZkt(uint256 _zktMaxCap) external onlyOwner {
        zktMaxCap = _zktMaxCap;
    }

    function setMaxCapEth(uint256 _ethMaxCap) external onlyOwner {
        ethMaxCap = _ethMaxCap;
    }
}