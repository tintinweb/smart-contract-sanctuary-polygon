// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IManagers {
    function isManager(address _address) external view returns (bool);

    function approveTopic(string memory _title, bytes memory _encodedValues) external;

    function cancelTopicApproval(string memory _title) external;

    function deleteTopic(string memory _title) external;

    function isApproved(string memory _title, bytes memory _value) external view returns (bool);

    function changeManager1(address _newAddress) external;

    function changeManager2(address _newAddress) external;

    function changeManager3(address _newAddress) external;

    function changeManager4(address _newAddress) external;

    function changeManager5(address _newAddress) external;

    function addAddressToTrustedSources(address _address, string memory _name) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IManagers.sol";


contract Vault {
    //Structs
    struct VestingInfo {
        uint256 amount;
        uint256 unlockTime;
        bool released;
    }

    //Storage Variables
    IManagers managers;
    address public soulsTokenAddress;
    address public mainVaultAddress;

    uint256 public currentVestingIndex;
    /**
	@dev must be assigned in constructor on of these: 
	"Marketing", "Advisor", "Airdrop", "Exchanges", "Treasury" or "Team"
	 */
    string public vaultName;

    VestingInfo[] public tokenVestings;

    //Custom Errors
    error OnlyOnceFunctionWasCalledBefore();
    error WaitForNextVestingReleaseDate();
    error NotAuthorized_ONLY_MAINVAULT();
    error NotAuthorized_ONLY_MANAGERS();
    error DifferentParametersLength();
    error InvalidFrequency();
    error NotEnoughAmount();
    error NoMoreVesting();
    error TransferError();
    error ZeroAmount();

    //Events
    event Withdraw(uint256 date, uint256 amount, bool isApproved);
    event ReleaseVesting(uint256 date, uint256 vestingIndex);

    constructor(
        string memory _vaultName,
        address _mainVaultAddress,
        address _soulsTokenAddress,
        address _managersAddress
    ) {
        vaultName = _vaultName;
        mainVaultAddress = _mainVaultAddress;
        soulsTokenAddress = _soulsTokenAddress;
        managers = IManagers(_managersAddress);
    }

	//Modifiers
    modifier onlyOnce() {
        if (tokenVestings.length > 0) {
            revert OnlyOnceFunctionWasCalledBefore();
        }
        _;
    }

    modifier onlyMainVault() {
        if (msg.sender != mainVaultAddress) {
            revert NotAuthorized_ONLY_MAINVAULT();
        }
        _;
    }

    modifier onlyManager() {
        if (!managers.isManager(msg.sender)) {
            revert NotAuthorized_ONLY_MANAGERS();
        }
        _;
    }

    // Write Functions
    /** TEST INFO
	 (Calling by Main Vault)
	 **** Cannot init more than one for each vault
	 * Vault init edildikten sonra yeniden init edilmesi denendiğinde 'Already Inited' hatası döndüğü gözlemlenmiştir.

	 **** Total of vestings must be equal to locked tokens
	 Init işlemi sırasında contracta kilitlenen token miktarının vault share miktarına eşit olduğu gözlemlenmiştir.
┌─────────┬─────────────┬───────────────────┐
│ (index) │   amount    │    releaseDate    │
├─────────┼─────────────┼───────────────────┤
│    0    │ '6250000.0' │ 'Fri Feb 23 2024' │
│    1    │ '6250000.0' │ 'Sun Mar 24 2024' │
│    2    │ '6250000.0' │ 'Tue Apr 23 2024' │
│    3    │ '6250000.0' │ 'Thu May 23 2024' │
│    4    │ '6250000.0' │ 'Sat Jun 22 2024' │
│    5    │ '6250000.0' │ 'Mon Jul 22 2024' │
│    6    │ '6250000.0' │ 'Wed Aug 21 2024' │
│    7    │ '6250000.0' │ 'Fri Sep 20 2024' │
│    8    │ '6250000.0' │ 'Sun Oct 20 2024' │
│    9    │ '6250000.0' │ 'Tue Nov 19 2024' │
│   10    │ '6250000.0' │ 'Thu Dec 19 2024' │
│   11    │ '6250000.0' │ 'Sat Jan 18 2025' │
│   12    │ '6250000.0' │ 'Mon Feb 17 2025' │
│   13    │ '6250000.0' │ 'Wed Mar 19 2025' │
│   14    │ '6250000.0' │ 'Fri Apr 18 2025' │
│   15    │ '6250000.0' │ 'Sun May 18 2025' │
│   16    │ '6250000.0' │ 'Tue Jun 17 2025' │
│   17    │ '6250000.0' │ 'Thu Jul 17 2025' │
│   18    │ '6250000.0' │ 'Sat Aug 16 2025' │
│   19    │ '6250000.0' │ 'Mon Sep 15 2025' │
│   20    │ '6250000.0' │ 'Wed Oct 15 2025' │
│   21    │ '6250000.0' │ 'Fri Nov 14 2025' │
│   22    │ '6250000.0' │ 'Sun Dec 14 2025' │
│   23    │ '6250000.0' │ 'Tue Jan 13 2026' │
└─────────┴─────────────┴───────────────────┘
Vault share:  150000000.0
Total amount of vestings:  150000000.0


	 **** 
	 */
    function createVestings(
        uint256 _totalAmount,
        uint256 _initialRelease,
        uint256 _initialReleaseDate,
        uint256 _countOfVestings,
        uint256 _vestingStartDate,
        uint256 _releaseFrequencyInDays
    ) public virtual onlyOnce onlyMainVault {
        if (_totalAmount == 0) {
            revert ZeroAmount();
        }

        if (_countOfVestings > 0 && _releaseFrequencyInDays == 0) {
            revert InvalidFrequency();
        }

        uint256 _amountUsed = 0;

        if (_initialRelease > 0) {
            tokenVestings.push(
                VestingInfo({amount: _initialRelease, unlockTime: _initialReleaseDate, released: false})
            );
            _amountUsed += _initialRelease;
        }
        uint256 releaseFrequency = _releaseFrequencyInDays * 1 days;

        if (_countOfVestings > 0) {
            uint256 _vestingAmount = (_totalAmount - _initialRelease) / _countOfVestings;

            for (uint256 i = 0; i < _countOfVestings; i++) {
                if (i == _countOfVestings - 1) {
                    _vestingAmount = _totalAmount - _amountUsed; //use remaining dusts from division
                }
                tokenVestings.push(
                    VestingInfo({
                        amount: _vestingAmount,
                        unlockTime: _vestingStartDate + (i * releaseFrequency),
                        released: false
                    })
                );
                _amountUsed += _vestingAmount;
            }
        }
    }

    //Managers function
    /** TEST INFO
     * Internal fonksiyona gözat
     */
    function withdrawTokens(address[] calldata _receivers, uint256[] calldata _amounts) external virtual onlyManager {
        _withdrawTokens(_receivers, _amounts);
    }

    /** TEST INFO
	 **** Cannot withdraw before unlock time
	 * Init işleminden sonra token çekilmesi denendiğinde 'WaitForNextVestingReleaseDate()' hatasının döndüğü gözlemlenmiştir.
	 
	 **** Relases next vesting automatically after unlockTime if released amount is not enough
	 * Blok zamanı ilk vestingin açılma zamanına simüle edilmiş ve 3 manager tarafından çekme talebinde bulunulmuştur.
	 * Contract üstünde ilk vesting'in released parametresinin true olduğu gözlemlenmiştir.
	 * Alıcı adresin balansının çekilen miktar kadar arttığı gözlemlenmiştir.
	 * Blok zamanı bir sonraki vesting'in açılma zamanına simüle edilmiş ve 3 manager tarafından çekme talebinde bulunulmuştur.
	 * Contract üstünde bir sonraki vesting'in released parametresinin true olduğu gözlemlenmiştir.
	 * 
	 **** Can work many times if there is enough relased amount
	 * Blok zamanı ilk vestingin açılma zamanına simüle edilmiş ve 3 manager tarafından çekme talebinde bulunulmuştur.
	 * 3 manager tarafından ilk vesting miktarının 1/3 miktarı çekilmiştir ve alıcı cüzdanın balansına yansıdığı gözlemlenmiştir.
	 * 3 manager tarafından bir kez daha ilk vesting miktarının 1/3 miktarı çekilmiştir ve alıcı cüzdanın balansına yansıdığı gözlemlenmiştir.
	 * 3 manager tarafından bir kez daha ilk vesting miktarının 1/3 miktarı çekilmiştir ve alıcı cüzdanın balansına yansıdığı gözlemlenmiştir.
	 * 1 Manager tarafından yeniden çekme isteği oluşturulmak istendiğinde 'WaitForNextVestingReleaseDate()' hatasının döndüğü gözlemlenmiştir.
	 
	 **** Can withdraw all vestings when unlocked
	 * Vestinglerin tamamının döngü ile blok zamanı vesting açılma zamanına simüle edilerek çekilmesinin başarılı olduğu gözlemlenmiştir.
	*/
    function _withdrawTokens(
        address[] memory _receivers,
        uint256[] memory _amounts
    ) internal returns (bool _isApproved) {
        if (_receivers.length != _amounts.length) {
            revert DifferentParametersLength();
        }

        uint256 _totalAmount = 0;
        for (uint256 a = 0; a < _amounts.length; a++) {
            if (_amounts[a] == 0) {
                revert ZeroAmount();
            }

            _totalAmount += _amounts[a];
        }

        uint256 _balance = IERC20(soulsTokenAddress).balanceOf(address(this));
        uint256 _amountWillBeReleased = 0;
        if (_totalAmount > _balance) {
            if (currentVestingIndex >= tokenVestings.length) {
                revert NoMoreVesting();
            }

            if (block.timestamp < tokenVestings[currentVestingIndex].unlockTime) {
                revert WaitForNextVestingReleaseDate();
            }

            for (uint256 v = currentVestingIndex; v < tokenVestings.length; v++) {
                if (tokenVestings[v].unlockTime > block.timestamp) break;
                _amountWillBeReleased += tokenVestings[v].amount;
            }

            if (_amountWillBeReleased + _balance < _totalAmount) {
                revert NotEnoughAmount();
            }
        }

        string memory _title = string.concat("Withdraw Tokens From ", vaultName);

        bytes memory _encodedValues = abi.encode(_receivers, _amounts);
        managers.approveTopic(_title, _encodedValues);
        _isApproved = managers.isApproved(_title, _encodedValues);
        if (_isApproved) {
            IERC20 _soulsToken = IERC20(soulsTokenAddress);
            if (_totalAmount > _balance) {
                //Needs to release new vesting

                for (uint256 v = currentVestingIndex; v < tokenVestings.length; v++) {
                    if (tokenVestings[v].unlockTime < block.timestamp) {
                        tokenVestings[v].released = true;
                        emit ReleaseVesting(block.timestamp, v);
                        currentVestingIndex++;
                    }
                }

                if (_amountWillBeReleased > 0) {
                    if (!_soulsToken.transferFrom(mainVaultAddress, address(this), _amountWillBeReleased)) {
                        revert TransferError();
                    }
                }
            }

            for (uint256 r = 0; r < _receivers.length; r++) {
                address _receiver = _receivers[r];
                uint256 _amount = _amounts[r];

                if (!_soulsToken.transfer(_receiver, _amount)) {
                    revert TransferError();
                }
            }
            managers.deleteTopic(_title);
        }

        emit Withdraw(block.timestamp, _totalAmount, _isApproved);
    }

	//Read Functions
    /** TEST INFO
     * Dolaylı olarak test edilmiştir.
     */
    function getVestingData() public view returns (VestingInfo[] memory) {
        return tokenVestings;
    }

    /** TEST INFO
     * Blok zamanı ilk vesting zamanına gidecek şekilde simüle edilmiştir.
     * Fonksiyonun ilk vestinge ait amount bilgisinin döndüğü gözlemlenmiştir.
     * 1 Token çekilmiş ve fonksiyon tekrar çağırıldığında ilk vesting amount bilgisinin bir eksiği döndüğü gözlemlenmiştir.
     * Blok zamanı bir sonraki vesting zamanına gidecek şekilde simüle edilmiştir.
     * Fonksiyonun ilk iki vestingin amount bilgilerinin toplamının 1 eksiğini döndürdüğü gözlemlenmiştir.
     */
    function getAvailableAmountForWithdraw() public view returns (uint256 _amount) {
        _amount = IERC20(soulsTokenAddress).balanceOf(address(this));
        for (uint256 v = currentVestingIndex; v < tokenVestings.length; v++) {
            if (tokenVestings[v].unlockTime > block.timestamp) break;
            _amount += tokenVestings[v].amount;
        }
    }
}