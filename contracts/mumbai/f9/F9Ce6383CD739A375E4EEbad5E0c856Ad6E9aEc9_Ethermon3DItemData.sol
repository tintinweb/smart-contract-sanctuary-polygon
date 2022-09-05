/**
 *Submitted for verification at polygonscan.com on 2022-09-05
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

// File: contracts/Ethermon3DItemBsic.sol

pragma solidity 0.6.6;

contract Ethermon3DItemBasic is BasicAccessControl {
    struct ItemData {
        uint32 id;
        uint256 price;
        uint256 qty;
    }

    struct Items {
        address owner;
        uint32[] itemId;
        uint256[] qty;
    }
}

// File: contracts/Ethermon3DItemData.sol

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

interface EthermonOracelInterface {
    function getEthRatesFromEmon(uint256 _amount)
        external
        view
        returns (uint256);

    function getEmonRatesFromEth(uint256 _amount)
        external
        view
        returns (uint256);
}

contract Ethermon3DItemData is Ethermon3DItemBasic {
    event ItemSold(
        address indexed _buyer,
        uint32[] indexed _itemId,
        uint256[] indexed _qty
    );

    mapping(uint32 => ItemData) public items;

    function setItem(
        uint32 _id,
        uint256 _price,
        uint256 _qty
    ) external onlyModerators {
        ItemData memory item = items[_id];
        item.id = _id;
        item.price = _price;
        item.qty = _qty;
        items[_id] = item;
    }

    function getItems(uint32 _itemId) public view returns (ItemData memory) {
        return items[_itemId];
    }

    function ItemBought(uint32 _itemId, uint256 _qty) external onlyModerators {
        ItemData storage item = items[_itemId];
        item.qty -= _qty;
    }

    function BoughtEvent(Items calldata _items) external onlyModerators {
        emit ItemSold(_items.owner, _items.itemId, _items.qty);
    }
}