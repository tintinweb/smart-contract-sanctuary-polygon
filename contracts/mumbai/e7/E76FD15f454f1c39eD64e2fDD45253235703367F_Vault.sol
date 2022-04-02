/**
 *Submitted for verification at polygonscan.com on 2022-04-01
*/

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

    event Withdrew(address _to, uint _amount);

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
        require(
            isOwner(_msgSender()),
            "RaffleDistributor: caller is not the owner"
        );
        _;
    }

    /**
     * @dev Returns true if caller is the address of the current owner.
     */
    function isOwner(address caller) public view virtual returns (bool) {
        return _owner[caller];
    }

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
        require(!paused(), "RaffleDistributor#Pausable: paused");
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
        require(paused(), "RaffleDistributor#Pausable: not paused");
        _;
    }

    function pause() public onlyOwner {
        _paused = true;
        emit Paused(_msgSender());
    }

    function unpause() public onlyOwner {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    receive() external payable {}

    fallback() external payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function authorizeSpender(address spender, bool val) public onlyOwner {
        authorized[spender] = val;
        if (val) {
            emit SpenderAccessGranted(spender);
        } else {
            emit SpenderAccessRevoked(spender);
        }
    }

    function OwnerWithdraw(uint256 amount) onlyOwner public returns(bool){
        (bool success, ) = payable(_msgSender()).call{value: amount}("");
        require(success,"Vault#withdraw: Failed");
        emit Withdrew(msg.sender, amount);
        return success;
    }


    function transferFromVault(address to, uint256 amount)
        public
        whenNotPaused
        requiresAuthorization
        returns (bool)
    {
        (bool success, ) = payable(to).call{value: amount}("");
        require(success,"Vault#transferFromVault: Failed");
        return success;
    }
}