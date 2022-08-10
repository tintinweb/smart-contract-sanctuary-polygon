/**
 *Submitted for verification at polygonscan.com on 2022-08-10
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

// File: contracts/EthermonBulkTransfer.sol

pragma solidity 0.6.6;


interface EthermonMonsterInterface {
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;
}

contract EthermonBulkTransfer is BasicAccessControl {
    address public ethermonMonsterContract;

    event Transfer(address from, address to, uint256 token);

    constructor(address _ethermonMonsterContract) public {
        ethermonMonsterContract = _ethermonMonsterContract;
    }

    function setContract(address _ethermonMonsterContract)
        external
        onlyModerators
    {
        ethermonMonsterContract = _ethermonMonsterContract;
    }

    function bulkTransfer(address[] calldata _to, uint256[] calldata _tokenId)
        external
        onlyModerators
    {
        EthermonMonsterInterface monster = EthermonMonsterInterface(
            ethermonMonsterContract
        );
        require(
            _tokenId.length == _to.length && msgSender() != address(0),
            "Value is valid."
        );

        for (uint256 i = 0; i < _to.length; i++) {
            if (_to[i] != address(0) && _tokenId[i] > 0) {
                monster.transferFrom(msgSender(), _to[i], _tokenId[i]);
                emit Transfer(msgSender(), _to[i], _tokenId[i]);
            }
        }
    }
}