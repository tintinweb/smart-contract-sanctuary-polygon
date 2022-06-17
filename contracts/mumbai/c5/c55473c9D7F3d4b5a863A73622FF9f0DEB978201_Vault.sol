// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.12;

contract Vault {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    event SpenderAccessGranted(address spender);
    event SpenderAccessRevoked(address spender);

    event Withdrawn(address _to, uint256 _amount);

    mapping(address => bool) private _owner;
    bool private _paused;

    mapping(address => bool) public authorized;

    constructor(address[] memory owner) {
        for (uint256 i = 0; i < owner.length; i++) {
            _owner[owner[i]] = true;
        }
        _paused = true;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(_msgSender()), "Vault: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if caller is the address of the current owner.
     */
    function isOwner(address caller) public view virtual returns (bool) {
        return _owner[caller];
    }

    /**
     * @dev Modifier to make a function callable only when the caller has been authorized by owner.
     *
     */
    modifier requiresAuthorization() {
        require(
            authorized[msg.sender],
            "Vault#requiresAuthorization: Sender not authorized"
        );
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Vault#Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Vault#Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external onlyOwner {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external onlyOwner {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    receive() external payable {}

    fallback() external payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Grants or revokes approval to `spender`, according to `val`,
     *
     * Emits {SpenderAccessGranted} or {SpenderAccessRevoked} event.
     *
     * Requirements:
     *
     * - `caller` must be owner.
     */
    function authorizeSpender(address spender, bool val) external onlyOwner {
        authorized[spender] = val;
        if (val) {
            emit SpenderAccessGranted(spender);
        } else {
            emit SpenderAccessRevoked(spender);
        }
    }

    /**
     * @dev allows owner to withdraw vault balance
     *
     * Emits {Withdrawn} event.
     */
    function OwnerWithdraw(uint256 amountInWei) external onlyOwner returns (bool) {
        require(amountInWei <= getBalance(),"Vault#withdraw: amount exceeds vault Balance");
        (bool success, ) = payable(_msgSender()).call{value: amountInWei}("");
        require(success, "Vault#withdraw: Failed");
        emit Withdrawn(msg.sender, amountInWei);
        return success;
    }

    /**
     * @dev allows authorized caller to transfer `amountInWei` wei from vault to address `to`
     *
     */
    function transferFromVault(address to, uint256 amountInWei)
        external
        whenNotPaused
        requiresAuthorization
        returns (bool)
    {
        require(amountInWei <= getBalance(),"Vault#transferFromVault: amount exceeds vault Balance");
        (bool success, ) = payable(to).call{value: amountInWei}("");
        require(success, "Vault#transferFromVault: Failed");
        emit Withdrawn(to, amountInWei);
        return success;
    }
}