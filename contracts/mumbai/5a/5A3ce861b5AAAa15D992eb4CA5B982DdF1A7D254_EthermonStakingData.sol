/**
 *Submitted for verification at polygonscan.com on 2022-05-17
*/

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

// File: contracts/EthermonStakingData.sol

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

contract EthermonStakingBasic is BasicAccessControl {
    struct TokenData {
        uint256 tokenId;
        uint256 day;
        uint256 amount;
    }
}

contract EthermonStakingData is EthermonStakingBasic {
    mapping(address => TokenData[]) public tokenIds;

    function addTokenData(
        address _owner,
        uint256 _day,
        uint256 _amount
    ) public onlyModerators {
        TokenData[] storage data = tokenIds[_owner];
        uint256 tokenId = getRandom(data.length + 1, block.number - 1);
        TokenData memory newData = TokenData(tokenId, _day, _amount);
        //newData.day = _day;
        //newData.tokenId = getRandom(data.length + 1, block.number - 1);
        //newData.amount = _amount;
        data.push(newData);
    }

    function getTokenData(address _owner)
        public
        view
        returns (TokenData[] memory)
    {
        return (tokenIds[_owner]);
    }

    function removeTokenData(address _owner, uint256 _index)
        public
        onlyModerators
    {
        TokenData[] storage data = tokenIds[_owner];
        uint256 foundIndex = _index;
        if (data[foundIndex].day > block.timestamp) revert();

        data[foundIndex] = data[data.length - 1];
        data.pop();
    }

    function getRandom(uint256 _count, uint256 _block)
        private
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(blockhash(_block), _count)));
    }
}