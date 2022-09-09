/**
 *Submitted for verification at polygonscan.com on 2022-09-09
*/

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/utils/Address.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

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

// File: contracts/Ethermon3DItem.sol

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

interface Ethermon3DItemData {
    function ItemBought(uint32 _itemId, uint256 _qty) external;

    function getItems(uint32 _itemId)
        external
        returns (Ethermon3DItemBasic.ItemData memory);

    function BoughtEvent(Ethermon3DItemBasic.Items calldata _items) external;
}

contract Ethermon3DItem is Ethermon3DItemBasic {
    using SafeERC20 for IERC20;

    IERC20 public emon;

    address public emonOracle;
    address public itemData;

    mapping(uint256 => ItemData) public items;

    constructor(
        address _emon,
        address _emonOracle,
        address _itemData
    ) public {
        emon = IERC20(_emon);
        itemData = _itemData;
        emonOracle = _emonOracle;
    }

    function setContract(address _emonOracle, address _itemData)
        external
        onlyModerators
    {
        emonOracle = _emonOracle;
        itemData = _itemData;
    }

    function setItem(
        uint32 _id,
        uint256 _price,
        uint256 _qty
    ) external onlyModerators {
        require(_price > 0, "Price is invalid");
        require(_id > 0, "Provided ID invalid");

        ItemData storage item = items[_id];
        item.price = _price;
        item.qty = _qty;
    }

    function withdrawEmon(address _sendTo, uint256 _amount) public onlyOwner {
        uint256 balance = emon.balanceOf(address(this));

        require(_amount <= balance, "Not enough balance!!");

        emon.safeTransfer(_sendTo, _amount);
    }

    function getPriceEmon(uint32 _itemId)
        external
        view
        returns (uint256 price)
    {
        EthermonOracelInterface emonOracleData = EthermonOracelInterface(
            emonOracle
        );
        ItemData memory item = items[_itemId];

        price = emonOracleData.getEmonRatesFromEth(item.price);
        return price;
    }

    function buyItem(uint32[] calldata _itemIds, uint256[] calldata _qtys)
        external
        isActive
    {
        require(
            _itemIds.length == _qtys.length &&
                _qtys.length > 0 &&
                _itemIds.length > 0,
            "Some Items or Qunatity missing"
        );
        Ethermon3DItemData itemDataContract = Ethermon3DItemData(itemData);

        EthermonOracelInterface emonOracleData = EthermonOracelInterface(
            emonOracle
        );
        uint256 amount = 0;

        Items memory boughtItems;
        boughtItems.owner = msgSender();

        uint32[] memory itemIds = new uint32[](_itemIds.length - 1);
        uint256[] memory qtys = new uint256[](_qtys.length - 1);

        for (uint256 i = 0; i < _itemIds.length; i++) {
            ItemData memory item = itemDataContract.getItems(_itemIds[i]);
            require(
                item.qty > _qtys[i] && item.qty > 0,
                "Invalid quantity of item"
            );
            uint256 priceInEmon = emonOracleData.getEmonRatesFromEth(
                item.price
            );
            amount += priceInEmon * _qtys[i];
            require(amount >= priceInEmon, "Amount too low");
            emit LOGS(amount);
            require(
                emon.balanceOf(msgSender()) >= amount,
                "Insufficitn balance"
            );
            item.qty -= _qtys[i];

            itemIds[i] = item.id;
            qtys[i] = item.qty;

            itemDataContract.ItemBought(item.id, item.qty);
        }
        boughtItems.itemId = itemIds;
        boughtItems.qty = qtys;

        emon.safeTransferFrom(msgSender(), address(this), amount);
        itemDataContract.BoughtEvent(boughtItems);
    }

    event LOGS(uint256 _amount);
}