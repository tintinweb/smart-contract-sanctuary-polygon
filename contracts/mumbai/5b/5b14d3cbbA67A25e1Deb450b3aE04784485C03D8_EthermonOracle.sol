/**
 *Submitted for verification at polygonscan.com on 2022-09-15
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
        } else {
            delete moderators[_newModerator];
            totalModerators -= 1;
        }
    }

    function Kill() public onlyOwner {
        selfdestruct(owner);
    }
}

// File: contracts/EthermonOracle.sol

pragma solidity 0.6.6;

contract EthermonOracle is BasicAccessControl {
    uint256 emonsInEth = 0;
    // EMON price per dollar
    uint256 public emonPrice = 0;
    // ETH price per dollar
    uint256 public ethPrice = 0;

    uint256 emonCap = 0;
    uint256 ethCap = 0;
    uint256 emonMaxCap = 0;
    uint256 ethMaxCap = 0;

    constructor() public {
        ethMaxCap = 1 * 10**18;
        emonMaxCap = 1 * 10**18;
    }

    /**
        @param _amount: uint256 => Amount in ETH 
        @return Price in EMON
        Disctiption: Pass 1 ETH get value in EMON
    */
    function getEmonRatesFromEth(uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint256 ethP = ethPrice * _amount;
        uint256 emonP = emonPrice * 10**18;

        uint256 rate = ethP / emonP;
        if (rate <= 0) {
            rate = (ethP * 10**18) / emonP;
            rate = (rate < ethCap) ? ethCap : rate;
            return rate;
        }
        rate = rate * 10**18;
        rate = (rate < ethCap) ? ethCap : rate;

        return rate;
    }

    /**
        @param _amount: uint256 => Amount in EMON 
        @return Price in ETH
        Disctiption: Pass 1 EMON get value in ETH
    */
    function getEthRatesFromEmon(uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint256 emonP = emonPrice * _amount;
        uint256 ethP = ethPrice * 10**18;

        uint256 rate = emonP / ethP;
        if (rate <= 0) {
            rate = (emonP * 10**18) / ethP;
            rate = (rate < emonCap) ? emonCap : rate;
            return rate;
        }
        rate = (rate < emonCap) ? emonCap : rate;

        return rate;
    }

    function updatePrices(uint256 _emonPrice, uint256 _ethPrice)
        external
        onlyModerators
    {
        if (_emonPrice < emonCap) emonPrice = _emonPrice;
        if (_ethPrice < ethCap) ethPrice = _ethPrice;

        ethPrice = _ethPrice;
        emonPrice = _emonPrice;
    }

    function setCapEmon(uint256 _emonCap) external onlyModerators {
        require(_emonCap < emonMaxCap, "Cannot put cap lesser than 0");
        emonCap = _emonCap;
    }

    function setCapEth(uint256 _ethCap) external onlyModerators {
        require(_ethCap <= ethMaxCap, "Cannot put cap lesser than 0");
        ethCap = _ethCap;
    }

    function setMaxCapEmon(uint256 _emonMaxCap) external onlyOwner {
        emonMaxCap = _emonMaxCap;
    }

    function setMaxCapEth(uint256 _ethMaxCap) external onlyOwner {
        ethMaxCap = _ethMaxCap;
    }
}