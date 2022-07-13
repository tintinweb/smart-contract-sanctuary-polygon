/**
 *Submitted for verification at polygonscan.com on 2022-07-13
*/

/** 
 *  SourceUnit: c:\Users\ASUS\OneDrive\Desktop\Code\blockchain\FINT\backend\contracts\infrastructure\2FA\2FA.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}




/** 
 *  SourceUnit: c:\Users\ASUS\OneDrive\Desktop\Code\blockchain\FINT\backend\contracts\infrastructure\2FA\2FA.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


/** 
 *  SourceUnit: c:\Users\ASUS\OneDrive\Desktop\Code\blockchain\FINT\backend\contracts\infrastructure\2FA\2FA.sol
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

////import "@openzeppelin/contracts/access/Ownable.sol";

contract FA2 is Ownable {
    struct OTP {
        uint256 time;
        bytes32 device_id;
        string[] otp;
    }

    mapping(address => OTP) private otps;

    address[] WALLET_ADDRESS;
    address[] CONTRACT_ADDRESS;

    uint256 time_to_wait;

    modifier onlyWallet() {
        bool found = false;
        for (uint256 i = 0; i < WALLET_ADDRESS.length; ) {
            if (WALLET_ADDRESS[i] == msg.sender) {
                found = true;
                break;
            }
            unchecked {
                i++;
            }
        }

        if (!found) {
            revert("KOMET: Not a Wallet");
        }

        _;
    }

    modifier onlyContract() {
        bool found = false;
        for (uint256 i = 0; i < CONTRACT_ADDRESS.length; ) {
            if (CONTRACT_ADDRESS[i] == msg.sender) {
                found = true;
                break;
            }
            unchecked {
                i++;
            }
        }

        if (!found) {
            revert("KOMET: Not a Contract");
        }

        _;
    }

    modifier onlyWalletOrContract() {
        bool found = false;
        for (uint256 i = 0; i < CONTRACT_ADDRESS.length; ) {
            if (CONTRACT_ADDRESS[i] == msg.sender) {
                found = true;
                break;
            }
            if (WALLET_ADDRESS[i] == msg.sender) {
                found = true;
                break;
            }
            unchecked {
                i++;
            }
        }

        if (!found) {
            revert("KOMET: Not a Wallet or Contract");
        }

        _;
    }

    event WalletListUpdated(address[] wallets);
    event ContractListUpdated(address[] wallets);
    event TimeToWaitUpdated(uint256 time_to_wait);

    constructor(
        address[] memory wallet_address,
        address[] memory contract_address,
        uint256 _time_to_wait
    ) {
        WALLET_ADDRESS = wallet_address;
        CONTRACT_ADDRESS = contract_address;
        time_to_wait = _time_to_wait;
    }

    function addWalletAddress(address wallet) public onlyOwner {
        WALLET_ADDRESS.push(wallet);

        emit WalletListUpdated(WALLET_ADDRESS);
    }

    function addContractAddress(address _contract) public onlyOwner {
        CONTRACT_ADDRESS.push(_contract);

        emit ContractListUpdated(CONTRACT_ADDRESS);
    }

    function updateTimeToWait(uint256 _time_to_wait) public onlyOwner {
        time_to_wait = _time_to_wait;

        emit TimeToWaitUpdated(time_to_wait);
    }

    function addOTP(
        address _wallet,
        string memory device_id,
        string[] calldata _otp
    ) public onlyWallet {
        OTP memory otp = OTP(
            block.timestamp,
            keccak256(bytes(device_id)),
            _otp
        );

        otps[_wallet] = otp;
    }

    function usedOTP(
        address _wallet,
        string memory device_id,
        string memory otp
    ) public view onlyContract returns (bool) {
        require(
            block.timestamp - otps[_wallet].time <= time_to_wait,
            "KOMET: 10 Min passed since OTP was generated"
        );
        require(
            keccak256(bytes(device_id)) == otps[_wallet].device_id,
            "KOMET: device_id is not matching"
        );

        string[] memory current_otps = otps[_wallet].otp;
        bool found = false;
        for (uint256 i = 0; i < current_otps.length; ) {
            if (keccak256(bytes(current_otps[i])) == keccak256(bytes(otp))) {
                found = true;
                break;
            }
            unchecked {
                i++;
            }
        }

        if (!found) {
            revert("KOMET: OTP doesn't match");
        }

        return true;
    }
}