// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.9;

contract CoinOpAccessControl {
    string public symbol;
    string public name;

    mapping(address => bool) private admins;
    mapping(address => bool) private writers;

    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event WriterAdded(address indexed admin);
    event WriterRemoved(address indexed admin);

    modifier onlyAdmin() {
        require(
            admins[msg.sender],
            "CoinOpAccessControl: Only admins can perform this action"
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol
    ) {
        symbol = _symbol;
        name = _name;
        admins[msg.sender] = true;
    }

    function addAdmin(address _admin) external onlyAdmin {
        require(
            !admins[_admin] && _admin != msg.sender,
            "CoinOpAccessControl: Cannot add existing admin or yourself"
        );
        admins[_admin] = true;
        emit AdminAdded(_admin);
    }

    function removeAdmin(address _admin) external onlyAdmin {
        require(
            _admin != msg.sender,
            "CoinOpAccessControl: Cannot remove yourself as admin"
        );
        require(admins[_admin], "CoinOpAccessControl: Admin doesn't exist.");
        admins[_admin] = false;
        emit AdminRemoved(_admin);
    }

    function addWriter(address _writer) external onlyAdmin {
        require(
            !writers[_writer],
            "CoinOpAccessControl: Cannot add existing writer"
        );
        writers[_writer] = true;
        emit WriterAdded(_writer);
    }

    function removeWriter(address _writer) external onlyAdmin {
        require(
            writers[_writer],
            "CoinOpAccessControl: Cannot remove a writer that doesn't exist"
        );
        writers[_writer] = false;
        emit WriterRemoved(_writer);
    }

    function isAdmin(address _address) public view returns (bool) {
        return admins[_address];
    }

    function isWriter(address _address) public view returns (bool) {
        return writers[_address];
    }
}

// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.9;

import "./CoinOpAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CoinOpFulfillment {
    CoinOpAccessControl private _accessControl;
    uint256 private _fullfillerCount;
    uint256 private _activeFulfillers;
    string public symbol;
    string public name;

    struct Fulfiller {
        uint256 fulfillerId;
        uint256 fulfillerPercent;
        address fulfillerAddress;
    }

    mapping(uint256 => Fulfiller) private _fulfillers;

    event AccessControlUpdated(
        address indexed oldAccessControl,
        address indexed newAccessControl,
        address updater
    );

    event FulfillerAddressUpdated(
        uint256 indexed fulfillerId,
        address newFulfillerAddress
    );

    event FulfillerCreated(
        uint256 indexed fulfillerId,
        uint256 fulfillerPercent,
        address fulfillerAddress
    );

    event FulfillerPercentUpdated(
        uint256 indexed fulfillerId,
        uint256 newFulfillerPercent
    );

    modifier onlyAdmin() {
        require(
            _accessControl.isAdmin(msg.sender),
            "CoinOpAccessControl: Only admin can perform this action"
        );
        _;
    }

    modifier onlyFulfiller(uint256 _fulfillerId) {
        require(
            msg.sender == _fulfillers[_fulfillerId].fulfillerAddress,
            "CoinOpFulfillment: Only the fulfiller can update."
        );
        _;
    }

    constructor(
        address _accessControlContract,
        string memory _symbol,
        string memory _name
    ) {
        _accessControl = CoinOpAccessControl(_accessControlContract);
        symbol = _symbol;
        name = _name;
        _fullfillerCount = 0;
    }

    function createFulfiller(
        uint256 _fulfillerPercent,
        address _fulfillerAddress
    ) external onlyAdmin {
        require(
            _fulfillerPercent < 100,
            "CoinOpFulfillment: Percent can not be greater than 100."
        );
        _fullfillerCount++;
        _activeFulfillers++;

        Fulfiller memory newFulfiller = Fulfiller({
            fulfillerId: _fullfillerCount,
            fulfillerPercent: _fulfillerPercent,
            fulfillerAddress: _fulfillerAddress
        });

        _fulfillers[_fullfillerCount] = newFulfiller;

        emit FulfillerCreated(
            _fullfillerCount,
            _fulfillerPercent,
            _fulfillerAddress
        );
    }

    function updateAccessControl(
        address _newAccessControlAddress
    ) external onlyAdmin {
        address oldAddress = address(_accessControl);
        _accessControl = CoinOpAccessControl(_newAccessControlAddress);
        emit AccessControlUpdated(
            oldAddress,
            _newAccessControlAddress,
            msg.sender
        );
    }

    function updateFulfillerPercent(
        uint256 _fulfillerId,
        uint256 _fulfillerPercent
    ) public onlyFulfiller(_fulfillerId) {
        require(
            _fulfillerId <= _fullfillerCount,
            "CoinOpFulfillment: Fulfiller does not exist."
        );
        _fulfillers[_fulfillerId].fulfillerPercent = _fulfillerPercent;
        emit FulfillerPercentUpdated(_fulfillerId, _fulfillerPercent);
    }

    function updateFulfillerAddress(
        uint256 _fulfillerId,
        address _newFulfillerAddress
    ) public onlyFulfiller(_fulfillerId) {
        require(
            _fulfillers[_fulfillerId].fulfillerId != 0,
            "CoinOpFulfillment: Fulfiller does not exist."
        );
        _fulfillers[_fulfillerId].fulfillerAddress = _newFulfillerAddress;
        emit FulfillerAddressUpdated(_fulfillerId, _newFulfillerAddress);
    }

    function removeFulfiller(uint256 _fulfillerId) public onlyAdmin {
        delete _fulfillers[_fulfillerId];
        _activeFulfillers -= 1;
    }

    function getFulfillerAddress(
        uint256 _fulfillerId
    ) public view returns (address) {
        return _fulfillers[_fulfillerId].fulfillerAddress;
    }

    function getFulfillerCount() public view returns (uint256) {
        return _activeFulfillers;
    }

    function getFulfillerPercent(
        uint256 _fulfillerId
    ) public view returns (uint256) {
        return _fulfillers[_fulfillerId].fulfillerPercent;
    }

    function getAccessControlContract() public view returns (address) {
        return address(_accessControl);
    }
}