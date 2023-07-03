// SPDX-License-Identifier: MIT
/*
 *
 *    Web:      
 *    Discord:  
 *    Twitter:  
 */


import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./IterableMapping.sol";

pragma solidity 0.8.4;

contract VaultsManager is Ownable, Pausable {
    using SafeMath for uint256;
    using IterableMapping for IterableMapping.Map;

    struct VaultsEntity {
        string name;
        uint id;
        uint creationTime;
        uint lastClaimTime;
        uint256 amount;
        address owner;
    }

     struct Offer {
        bool isForSale;
        uint id;
        address seller;
        uint minValue;          // in ether
        address onlySellTo;     // specify to sell only to a specific person
    }

    // A record of punks that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping (uint => Offer) public vaultsOfferedForSale;

    IterableMapping.Map private vaultsOwners;
    mapping(address => VaultsEntity[]) private _vaultsOfUser;
    VaultsEntity[] public allVaults;

    address public token;
    uint8 public rewardPerVaults;
    uint256 public minPrice = 500 ether;

    uint256 public totalVaultsCreated = 0;
    uint256 public maxVaultsCreated = 10000;
    uint256 public maxVaultValue = 5000 ether;
    uint256 public totalStaked = 0;
    uint256 public maxTotalStaked = 25000000 ether;
    uint256 public totalClaimed = 0;
    uint256 public maxVaultCreated = 20;

    event VaultCreated(
        uint256 indexed amount,
        address indexed account,
        uint indexed blockTime
    );

    event VaultOffered(uint indexed id, uint minValue, address indexed toAddress);
    event VaultBought(uint indexed id, uint value, address indexed fromAddress, address indexed toAddress);
    event VaultNoLongerForSale(uint indexed id);

    modifier onlyGuard() {
        require(owner() == _msgSender() || token == _msgSender(), "NOT_GUARD");
        _;
    }

    modifier onlyVaultsOwner(address account) {
        require(isVaultOwner(account), "NOT_OWNER");
        _;
    }

    constructor(
        uint8 _rewardPerVault
    ) {
        rewardPerVaults = _rewardPerVault;
    }

    // Private methods

    function _isNameAvailable(address account, string memory vaultName)
        private
        view
        returns (bool)
    {
        VaultsEntity[] memory vaults = _vaultsOfUser[account];
        for (uint256 i = 0; i < vaults.length; i++) {
            if (keccak256(bytes(vaults[i].name)) == keccak256(bytes(vaultName))) {
                return false;
            }
        }
        return true;
    }


    function _uint2str(uint256 _i)
        private
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function _calculateVaultRewards(uint _lastClaimTime, uint256 amount_) private view returns (uint256 rewards) {
        uint256 elapsedTime_ = (block.timestamp - _lastClaimTime);
        uint256 rewardPerDay = amount_.mul(rewardPerVaults).div(100);
        return ((rewardPerDay.mul(10000).div(1440) * (elapsedTime_ / 1 minutes)) / 10000);
    }

    function _getVaultReward(address account, uint256 id)
        public
        view
        returns (uint256)
    {
        VaultsEntity[] storage vaults = _vaultsOfUser[account];
        require(
            vaults.length > 0,
            "CASHOUT ERROR: You don't have vaults to cash-out"
        );
        VaultsEntity storage vault = vaults[id];
        return _calculateVaultRewards(vault.lastClaimTime, vault.amount);
    }

    function _vaultsAvailable()
        private
        view
        returns (bool)
    {
        if (totalVaultsCreated >= maxVaultsCreated) {
            return false;
        } else {
            return true;
        }
    }

        function _vaultsValueAvailable()
        private
        view
        returns (bool)
    {
        if (totalStaked >= maxTotalStaked) {
            return false;
        } else {
            return true;
        }
    }

    function _getIndexOfKey(address account) private view returns (int256) {
        require(account != address(0));
        return vaultsOwners.getIndexOfKey(account);
    }

    function _burn(uint256 index) private  {
        require(index < vaultsOwners.size());
        vaultsOwners.remove(vaultsOwners.getKeyAtIndex(index));
    }

    // External methods

    function createVault(address account, string memory vaultName, uint256 amount_) external onlyGuard whenNotPaused {
        require(
            _vaultsAvailable(), "Maximum Vaults reached"
        );
        require(
            _isNameAvailable(account, vaultName),
            "Name not available"
        );
        require(
            _vaultsValueAvailable(), "Maximum Vaults Value reached"
        );
        VaultsEntity[] storage _vaults = _vaultsOfUser[account];
        require(_vaults.length < maxVaultCreated, "Max vaults exceeded");
        _vaults.push(
            VaultsEntity({
                name: vaultName,
                id: totalVaultsCreated,
                creationTime: block.timestamp,
                lastClaimTime: block.timestamp,
                amount: amount_,
                owner: account
            })
        );
        allVaults.push(
            VaultsEntity({
                name: vaultName,
                id: totalVaultsCreated,
                creationTime: block.timestamp,
                lastClaimTime: block.timestamp,
                amount: amount_,
                owner: account
            })
        );
        vaultsOwners.set(account, _vaultsOfUser[account].length);
        emit VaultCreated(amount_, account, block.timestamp);
        totalVaultsCreated++;
        totalStaked += amount_;
    }

    function getVaultsRewards(address account)
        public
        view
        returns (uint256)
    {
        VaultsEntity[] storage vaults = _vaultsOfUser[account];
        uint256 vaultsCount = vaults.length;
        require(vaultsCount > 0, "NODE: CREATIME must be higher than zero");
        VaultsEntity storage _vault;
        uint256 rewardsTotal = 0;
        for (uint256 i = 0; i < vaultsCount; i++) {
            _vault = vaults[i];
            rewardsTotal += _calculateVaultRewards(_vault.lastClaimTime, _vault.amount);
        }
        return rewardsTotal;
    }

    function getCurrentVaultOwnerOffer(uint id) external view returns (address) {
        Offer storage offer = vaultsOfferedForSale[id];
        return offer.seller;
    }

    function compoundVaultReward(address account)
        external
        onlyGuard
        onlyVaultsOwner(account)
        whenNotPaused
    {
        require(
            _vaultsValueAvailable(), "Maximum Vaults Value reached"
        );
        VaultsEntity[] storage vaults = _vaultsOfUser[account];
        require(
            vaults.length > 0,
            "CASHOUT ERROR: You don't have vaults to cash-out"
        );
        for (uint256 i = 0; i < vaults.length; i++) {
            VaultsEntity storage vault = vaults[i];
            uint256 rewardAmount_ = _getVaultReward(account, i);
            vault.amount += rewardAmount_;
            uint id = vault.id;
            allVaults[id].amount += rewardAmount_;
            vault.lastClaimTime = block.timestamp;
            totalStaked += rewardAmount_;
        }
    }

    function cashoutVaultsRewards(address account)
        external
        onlyGuard
        onlyVaultsOwner(account)
        whenNotPaused
    {
        VaultsEntity[] storage vaults = _vaultsOfUser[account];
        uint256 vaultsCount = vaults.length;
        require(vaultsCount > 0, "NODE: CREATIME must be higher than zero");
        VaultsEntity storage _vault;
        for (uint256 i = 0; i < vaultsCount; i++) {
            _vault = vaults[i];
            _vault.lastClaimTime = block.timestamp;
        }
    }

    function getVaultsNames(address account)
        public
        view
        onlyVaultsOwner(account)
        returns (string memory)
    {
        VaultsEntity[] memory vaults = _vaultsOfUser[account];
        uint256 vaultsCount = vaults.length;
        VaultsEntity memory _vault;
        string memory names = vaults[0].name;
        string memory separator = "#";
        for (uint256 i = 1; i < vaultsCount; i++) {
            _vault = vaults[i];
            names = string(abi.encodePacked(names, separator, _vault.name));
        }
        return names;
    }

    function getAllVaultsNames()
        public
        view
        returns (string memory)
    {
        uint256 vaultsCount = allVaults.length;
        VaultsEntity memory _vault;
        string memory names = allVaults[0].name;
        string memory separator = "#";
        for (uint256 i = 1; i < vaultsCount; i++) {
            _vault = allVaults[i];
            names = string(abi.encodePacked(names, separator, _vault.name));
        }
        return names;
    }

    function getVaultsCreationTime(address account)
        public
        view
        onlyVaultsOwner(account)
        returns (string memory)
    {
        VaultsEntity[] memory vaults = _vaultsOfUser[account];
        uint256 vaultsCount = vaults.length;
        VaultsEntity memory _vault;
        string memory _creationTimes = _uint2str(vaults[0].creationTime);
        string memory separator = "#";

        for (uint256 i = 1; i < vaultsCount; i++) {
            _vault = vaults[i];

            _creationTimes = string(
                abi.encodePacked(
                    _creationTimes,
                    separator,
                    _uint2str(_vault.creationTime)
                )
            );
        }
        return _creationTimes;
    }

    function getAllVaultsCreationTime()
        public
        view
        returns (string memory)
    {
        uint256 vaultsCount = allVaults.length;
        VaultsEntity memory _vault;
        string memory _creationTimes = _uint2str(allVaults[0].creationTime);
        string memory separator = "#";

        for (uint256 i = 1; i < vaultsCount; i++) {
            _vault = allVaults[i];

            _creationTimes = string(
                abi.encodePacked(
                    _creationTimes,
                    separator,
                    _uint2str(_vault.creationTime)
                )
            );
        }
        return _creationTimes;
    }

    function getAllAmount()
        public
        view
        returns (string memory)
    {
        uint256 vaultsCount = allVaults.length;
        VaultsEntity memory _vault;
        string memory _amount = _uint2str(allVaults[0].amount);
        string memory separator = "#";

        for (uint256 i = 1; i < vaultsCount; i++) {
            _vault = allVaults[i];

            _amount = string(
                abi.encodePacked(
                    _amount,
                    separator,
                    _uint2str(_vault.amount)
                )
            );
        }
        return _amount;
    }

    function getAllforSale()
        public
        view
        returns (string memory)
    {
        uint256 vaultsCount = allVaults.length;
        Offer memory _vault;
        string memory _isforSale;
        if (vaultsOfferedForSale[0].isForSale == false) {
            _isforSale = "false";
        } else {
            _isforSale = "true";
        }
        string memory separator = "#";

        for (uint256 i = 1; i < vaultsCount; i++) {
            _vault = vaultsOfferedForSale[i];
            string memory _result;
            if (_vault.isForSale == false) {
                _result = "false";
            } else {
                _result = "true";
            }

            _isforSale = string(
                abi.encodePacked(
                    _isforSale,
                    separator,
                    _result
                )
            );
        }
        return _isforSale;
    }

    function getAllforSalePrice()
        public
        view
        returns (string memory)
    {
        uint256 vaultsCount = allVaults.length;
        Offer memory _vault;
        string memory _minValue = _uint2str(vaultsOfferedForSale[0].minValue);
        string memory separator = "#";

        for (uint256 i = 1; i < vaultsCount; i++) {
            _vault = vaultsOfferedForSale[i];

            _minValue = string(
                abi.encodePacked(
                    _minValue,
                    separator,
                    _uint2str(_vault.minValue)
                )
            );
        }
        return _minValue;
    }

    function getVaultsLastClaimTime(address account)
        public
        view
        onlyVaultsOwner(account)
        returns (string memory)
    {
        VaultsEntity[] memory vaults = _vaultsOfUser[account];
        uint256 vaultsCount = vaults.length;
        VaultsEntity memory _vault;
        string memory _lastClaimTimes = _uint2str(vaults[0].lastClaimTime);
        string memory separator = "#";

        for (uint256 i = 1; i < vaultsCount; i++) {
            _vault = vaults[i];

            _lastClaimTimes = string(
                abi.encodePacked(
                    _lastClaimTimes,
                    separator,
                    _uint2str(_vault.lastClaimTime)
                )
            );
        }
        return _lastClaimTimes;
    }

    function updateToken(address newToken) external onlyOwner {
        token = newToken;
    }

    function updateReward(uint8 newVal) external onlyOwner {
        rewardPerVaults = newVal;
    }

    function updateMinPrice(uint256 newVal) external onlyOwner {
        minPrice = newVal;
    }

    function updateMaximumPrice(uint256 newVal) external onlyOwner {
        maxVaultValue = newVal;
    }

    function updateMaximumTotalStaked(uint256 newVal) external onlyOwner {
        maxTotalStaked = newVal;
    }

    function updateMaxVaults(uint256 newVal) external onlyOwner {
        maxVaultsCreated = newVal;
    }

    function updateMaxVaultPerAccount(uint256 newVal) external onlyOwner {
        maxVaultCreated = newVal;
    }

    function getMinPrice() external view returns (uint256) {
        return minPrice;
    }

    function getMaxPrice() external view returns (uint256) {
        return maxVaultValue;
    }

    function isVaultOwner(address account) public view returns (bool) {
        return vaultsOwners.get(account) > 0;
    }

    function getVaultNumberOf(address account) external view returns (uint256) {
        return vaultsOwners.get(account);
    }

    function getVaults(address account) external view returns (VaultsEntity[] memory) {
        return _vaultsOfUser[account];
    }

    function getIndexOfKey(address account) external view onlyGuard returns (int256) {
        require(account != address(0));
        return vaultsOwners.getIndexOfKey(account);
    }

    function burn(uint256 index) external onlyGuard {
        require(index < vaultsOwners.size());
        vaultsOwners.remove(vaultsOwners.getKeyAtIndex(index));
    }

    function offerVaultToSale(uint256 minSalePriceInWei, uint id) external {
        address account = _msgSender();
        require(
            allVaults[id].owner == account,
            "ERROR: You are not the owner of the vault"
        );
        vaultsOfferedForSale[id] = Offer(true, id, msg.sender, minSalePriceInWei, address(0));
        emit VaultOffered(id, minSalePriceInWei, address(0));
    }


    function offerVaultToSaleToAddress(uint256 minSalePriceInWei, address toAddress, uint id) external {
        address account = _msgSender();
        require(
            allVaults[id].owner == account,
            "ERROR: You are not the owner of the vault"
        );
        vaultsOfferedForSale[id] = Offer(true, id, msg.sender, minSalePriceInWei, toAddress);
        emit VaultOffered(id, minSalePriceInWei, toAddress);
    }
    
    function buyVault(uint id, uint256 _amount, string memory vaultName, address account) external onlyGuard {
        Offer storage offer = vaultsOfferedForSale[id];
        require(offer.isForSale, 'vault not for sale');                // vault not actually for sale
        require(offer.onlySellTo == address(0) || offer.onlySellTo == account, 'Offer is not available for this account');  // vault not supposed to be sold to this user
        require(_amount >= offer.minValue, 'amount is under minValue');      // Didn't send enough ETH
        require(offer.seller == allVaults[id].owner, 'seller is not the owner'); // Seller no longer owner of vault

        VaultsEntity[] storage _vaultsSeller = _vaultsOfUser[offer.seller];
        VaultsEntity[] storage _vaultsBuyer = _vaultsOfUser[account];

        require(_vaultsBuyer.length < maxVaultCreated, "Max vaults exceeded");

        allVaults[id].owner = account;
        allVaults[id].name = vaultName;
        uint256 amount_ = allVaults[id].amount;

        if (_vaultsSeller.length <= 1) {
            int256 key = vaultsOwners.getIndexOfKey(offer.seller);
            vaultsOwners.remove(vaultsOwners.getKeyAtIndex(uint256(key)));
        }

        uint256 index = 0;
        while (allVaults[id].id != _vaultsSeller[index].id) {
            index++;
        }

        _vaultsSeller[index] = _vaultsSeller[_vaultsSeller.length - 1];
        _vaultsSeller.pop();

        _vaultsBuyer.push(
            VaultsEntity({
                name: vaultName,
                id: id,
                creationTime: block.timestamp,
                lastClaimTime: block.timestamp,
                amount: amount_,
                owner: account
            })
        );
        vaultsOwners.set(account, _vaultsOfUser[account].length);
        vaultNoLongerForSale(id, account);
        
        emit VaultBought(id, _amount, offer.seller, account);
    }

    function vaultNoLongerForSale(uint id, address account) private {
        vaultsOfferedForSale[id] = Offer(false, id, account, 0, address(0));

        emit VaultNoLongerForSale(id);
    }

    function vaultNoLongerForSale(uint id) external {
        address account = _msgSender();
        require(allVaults[id].owner == account, 'sender is not the owner');
        vaultsOfferedForSale[id] = Offer(false, id, account, 0, address(0));

        emit VaultNoLongerForSale(id);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint256) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key)
        public
        view
        returns (int256)
    {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint256 index)
        public
        view
        returns (address)
    {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        uint256 val
    ) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
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
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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