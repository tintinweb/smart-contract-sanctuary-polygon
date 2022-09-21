/**
 *Submitted for verification at polygonscan.com on 2022-09-21
*/

// File: contracts/EthermonEnum.sol

pragma solidity 0.6.6;

contract EthermonEnum {
    enum ResultCode {
        SUCCESS,
        ERROR_CLASS_NOT_FOUND,
        ERROR_LOW_BALANCE,
        ERROR_SEND_FAIL,
        ERROR_NOT_TRAINER,
        ERROR_NOT_ENOUGH_MONEY,
        ERROR_INVALID_AMOUNT
    }

    enum ArrayType {
        CLASS_TYPE,
        STAT_STEP,
        STAT_START,
        STAT_BASE,
        OBJ_SKILL
    }

    enum BattleResult {
        CASTLE_WIN,
        CASTLE_LOSE,
        CASTLE_DESTROYED
    }

    enum PropertyType {
        ANCESTOR,
        XFACTOR
    }
}

// File: contracts/Context.sol

pragma solidity 0.6.6;


contract Context {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
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
    mapping (address => bool) public moderators;
    bool public isMaintaining = false;

    constructor() public {
        owner = msgSender();
    }

    modifier onlyOwner {
    require(msgSender() == owner);
        _;
    }

    modifier onlyModerators() {
        require(msgSender() == owner || moderators[msgSender()] == true);
        _;
    }

    modifier isActive {
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

// File: contracts/EthermonRerollPriceData.sol

pragma solidity 0.6.6;



interface EtheremonOracleInterface {
    function getEmonRatesFromEth(uint256 _amount) external
        view
        returns (uint256);
    

}

contract EthermonRerollPriceData is BasicAccessControl {

    mapping(uint32 => uint256) reRollPriceEth;
    address public oracleContract;

    function setRerollPrice(uint32 class_id, uint256 _price_in_eth)
        external
        onlyModerators
    {
        reRollPriceEth[class_id] = _price_in_eth;
    }

    function getRerollPriceEth(uint32 _classId)
        public
        view
        returns (uint256 price_in_emon)
    {
        return reRollPriceEth[_classId];
    }

    constructor(
     
        address _oracleContract


    ) public {
        oracleContract = _oracleContract;
       
    }

       function setContract(address _oracleContract)
        external
        onlyModerators
    {
        oracleContract = _oracleContract;
    }

    function getEmonPriceFromOracle(uint32 _classId)
        external
        view
        returns (uint256 price_in_emon)
    {
          uint256 class_price_eth = reRollPriceEth[_classId];
          require(class_price_eth > 0);
          EtheremonOracleInterface oracleContract = EtheremonOracleInterface(oracleContract);
        
        uint256 emonPrice = oracleContract.getEmonRatesFromEth(class_price_eth);
        return emonPrice;
    }

   
}