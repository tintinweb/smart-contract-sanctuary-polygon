/**
 *Submitted for verification at polygonscan.com on 2023-01-30
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.14;

// @openzepplin/contracts/utils/Strings
// License: MIT
library Utils {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;
    
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// @openzepplin/contracts/token/ERC20/IERC20
// License: MIT
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

/**
* @title Squid Contract Factory.
* @author Dream Kollab.
* @notice You can use this factory to create and interface with squids.
* @dev All function calls are currently implemented without side effects.
* @custom:developer Etienne Cellier-Clarke.
*/
contract Factory {

    address payable private owner;
    address private manager;

    uint public creation_fee;
    uint public transaction_fee;
    uint public id_counter;

    mapping(uint => Squid) private squids;
    mapping(address => uint) private squid_ids;
    mapping(address => uint[]) private asoc_squids;
    mapping(address => uint[]) private created_squids;

    modifier onlyOwner {
        require(msg.sender == owner, "Error: 1000");
        _;
    }

    modifier onlyManagement {
        require(msg.sender == owner || msg.sender == manager, "Error: 1000");
        _;
    }

    receive() external payable {}

    fallback() external payable {}

    constructor() {
        owner = payable(msg.sender);
        manager = msg.sender;
        creation_fee = 10000000000000000; // Wei
        transaction_fee = 1000000; // Fraction of 100000000
        id_counter = 5457;
    }

    function create(
        string memory _name,
        string memory _description,
        address[] memory _payees,
        uint[] memory _shares
    ) external payable {

        uint id = ++id_counter;

        require(!exists(id), 'Error: 1001');
        require(msg.value >= creation_fee, 'Error: 1002');
        require(bytes(_name).length <= 20, 'Error: 1003');
        require(bytes(_description).length <= 50, 'Error: 1003');
        require(_payees.length == _shares.length, 'Error: 1004');

        uint total_shares;
        for(uint16 i = 0; i < _shares.length; i++) {
            total_shares += _shares[i];
        }

        require(total_shares <= 1000000000000, 'Error: 1005');

        squids[id] = new Squid(
            _name,
            _description,
            _payees,
            _shares,
            total_shares,
            transaction_fee,
            msg.sender,
            address(this)
        );

        for(uint16 i = 0; i < _payees.length; i++) {
            asoc_squids[_payees[i]].push(id);
        }

        created_squids[msg.sender].push(id);

    }

    function getShareData(uint _id, address _account) public view returns (string[] memory) {
        string[] memory result;
        if(!exists(_id)) { return result; }
        return squids[_id].getData(_account);
    }

    function getIds(address _account) public view returns (uint[] memory) {
        return asoc_squids[_account];
    }

    function getCreatedIds(address _account) public view returns (uint[] memory) {
        return created_squids[_account];
    }

    function getShareholders(uint _id) public view returns (string[] memory) {
        return squids[_id].getShareholders();
    }

    function changeOwner(address _account) onlyOwner public {
        owner = payable(_account);
    }

    function changeManager(address _account) onlyOwner public {
        manager = _account;
    }

    function changeCreationFee(uint _fee) onlyOwner public {
        require(_fee >= 0, 'Error: 1006');
        creation_fee = _fee;
    }

    function changeTransactionFee(uint _fee) onlyOwner public {
        require(_fee >= 0, 'Error: 1006');
        transaction_fee = _fee;
    }

    function releaseFunds(IERC20 _token, bool _matic) onlyOwner public {
        if(!_matic) {
            _token.transfer(owner, _token.balanceOf(address(this)));
        } else {
            owner.transfer(address(this).balance);
        }
    }

    function flush(uint[] memory _ids, IERC20 _token, bool _matic) onlyManagement public {
        for(uint i = 0; i < _ids.length; i++) {
            if(!exists(_ids[i])) { continue; }
            if(!_matic) {
                squids[_ids[i]].payoutAllTokenized(_token);
            } else {
                squids[_ids[i]].payoutAll();
            }
        }
    }

    function payout(uint _id) external {
        squids[_id].payout(msg.sender);
    }

    function payoutAll(uint _id, IERC20 _token, bool _matic) external {
        require(squids[_id].getCreator() == msg.sender, 'Error: 1011');
        if(!_matic) {
            squids[_id].payoutAllTokenized(_token);
        } else {
            squids[_id].payoutAll();
        }
    }

    function exists(uint _id) private view returns (bool) {
        if(address(squids[_id]) != address(0)) {
            return true;
        }
        return false;
    }
}

/**
* @title Squid Smart Contract.
* @author Dream Kollab.
* @notice A Squid is a collection of crypto addresses each with an assigned number of shares.
* Once a Squid has been created it can no longer be modified and all share values are fixed.
* If a payee wants to withdraw any monies from the Squid they can only withdraw the amount
* they are entitled to which is determined by the amount of shares they have been allocated.
* The creator of the Squid has the ability to flush the contract and all payees will be
* transferred their share of any monies remaining.
* @dev All function calls are currently implemented without side effects.
* @custom:developer Etienne Cellier-Clarke.
*/
contract Squid {

    address factory;
    address creator;

    string name;
    string description;

    uint total_shares = 0;
    uint total_revenue = 0;
    uint fee;

    address[] payees;
    mapping(address => uint) shareholders;

    mapping(address => uint) total_released;
    mapping(address => uint) last_withdrawl;

    constructor(
        string memory _name,
        string memory _description,
        address[] memory _payees,
        uint[] memory _shares,
        uint _total_shares,
        uint _fee,
        address _creator,
        address _factory
    ) {
        name = _name;
        description = _description;
        total_shares = _total_shares;
        payees = _payees;
        fee = _fee;
        creator = _creator;
        factory = _factory;

        for(uint16 i = 0; i < _payees.length; i++) {
            shareholders[_payees[i]] = _shares[i];
        }
    }

    receive() external payable {
        uint transaction_fee = ( msg.value / 100000000 ) * fee;
        total_revenue = total_revenue + msg.value - transaction_fee;
        payable(factory).transfer(transaction_fee);
    }

    fallback() external payable {
        uint transaction_fee = ( msg.value / 100000000 ) * fee;
        total_revenue = total_revenue + msg.value - transaction_fee;
        payable(factory).transfer(transaction_fee);
    }

    function getData(address _account) public view returns (string[] memory) {
        string[] memory shareData = new string[](9);
        shareData[0] = Utils.toHexString(address(this));
        shareData[1] = name;
        shareData[2] = description;
        shareData[3] = Utils.toString(shareholders[_account]);
        shareData[4] = Utils.toString(total_shares);
        shareData[5] = Utils.toString(getUserBalance(_account));
        shareData[6] = Utils.toString(address(this).balance);
        shareData[7] = Utils.toString(last_withdrawl[_account]);
        shareData[8] = Utils.toHexString(creator);
        return shareData;
    }

    function getCreator() public view returns (address) {
        return creator;
    }

    function getUserBalance(address _payee) private view returns (uint) {
        return ( shareholders[_payee] * total_revenue ) / total_shares - total_released[_payee];
    }

    function isPayee(address _payee) private view returns (bool) {
        for(uint i = 0; i < payees.length; i++) {
            if(_payee == payees[i]) { return true; }
        }
        return false;
    }

    function getShareholders() public view returns (string[] memory) {
        string[] memory _shareholders = new string[](payees.length * 2);

        uint j = 0;
        for(uint i = 0; i < payees.length; i++) {
            address _payee = payees[i];
            _shareholders[j] = Utils.toHexString(_payee);
            _shareholders[j + 1] = Utils.toString(shareholders[_payee]);
            j = j + 2;
        }

        return _shareholders;
    }

    function payout(address _account) external {

        require(msg.sender == factory, 'Error: 1012');
        require(isPayee(_account), 'Error: 1007');
        require(shareholders[_account] > 0, 'Error: 1008');
        require(address(this).balance > 0, 'Error: 1009');

        uint bal = getUserBalance(_account);

        require(bal > 0, 'Error: 1010');

        total_released[_account] += bal;
        last_withdrawl[_account] = block.timestamp;

        (bool success, bytes memory data) = payable(_account).call{value: bal}("");
        require(success, "Failed to send ether");
    }

    function payoutAll() external {

        require(msg.sender == factory, 'Error: 1012');
        require(address(this).balance > 0, 'Error: 1009');

        for(uint i = 0; i < payees.length; i++) {

            address payee = payees[i];

            if(shareholders[payee] < 0) { continue; }

            uint bal = getUserBalance(payee);
            if(bal > 0) {
                // Track Data
                total_released[payee] += bal;
                last_withdrawl[payee] = block.timestamp;

                // Pay
                (bool success, bytes memory data) = payable(payee).call{value: bal}("");
                require(success, "Failed to send ether");
            }
        }
    }

    function payoutAllTokenized(IERC20 token) external {
        require(msg.sender == factory, 'Error: 1012');

        uint tokenBalance = token.balanceOf(address(this));
        uint transaction_fee = ( tokenBalance / 100000000 ) * fee;
        token.transfer(factory, transaction_fee);

        uint postFeeTokenBalance = tokenBalance - transaction_fee;
        for(uint i = 0; i < payees.length; i++) {
            address payee = payees[i];
            if(shareholders[payee] <= 0) { continue; }
            uint amount = shareholders[payee] * postFeeTokenBalance / total_shares;
            token.transfer(payee, amount);
        }
    }
}