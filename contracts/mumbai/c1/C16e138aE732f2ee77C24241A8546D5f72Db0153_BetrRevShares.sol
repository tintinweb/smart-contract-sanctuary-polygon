// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IXFUNToken.sol";
import "./interfaces/IBetrRevShares.sol";
 
contract BetrRevShares is IBetrRevShares, Ownable {

	IXFUNToken public tokenContract;

    constructor(address _tokenContract) {
		tokenContract = IXFUNToken(_tokenContract);
	}


	// System-Wide Layer Affiliate Revenue Share. This is the percentage taken off Bet Loss (Layer Win) for bets that have bettor related to affiliate(s)
	uint64 public layerAffiliatePercent; // Decimals 8

	function updateLayerAffiliatePercent(uint64 _percent) external onlyOwner { // Only Contract Owner may call this function
		require(_percent >= 0 && _percent < 10000000000);
		layerAffiliatePercent = _percent;

		emit UpdateLayerAffiliatePercent(_percent);
	}


	// GSP RevShare resultorAddress returns revShare. 1 revShare per Resultor.
	// GSP Rev Share is deducted from Bettor Loss (Layer Win) when bet resulted by this Resultor.
	mapping(address => revShare) resultorGSP;

	// Update Resultor / GSP RevShare
	function updateResultorGSP(address _resultorAddress, address _revSharePool, uint64 _percent) external onlyOwner { // Only Contract Owner may call this function

		require(_percent < 10000000000 && _percent > 0 && _resultorAddress != address(0) && _revSharePool != address(0));

		resultorGSP[_resultorAddress].revSharePool = _revSharePool;
		resultorGSP[_resultorAddress].percent = _percent;

		emit UpdateResultorGSP(_resultorAddress,_revSharePool,_percent);
	}

	function getResultorGSPRevSharePool(address _resultorAddress) external view returns (address) {
		return resultorGSP[_resultorAddress].revSharePool;
	}

	function getResultorGSPPercent(address _resultorAddress) external view returns (uint64) {
		return resultorGSP[_resultorAddress].percent;
	}

	// Relate a Bettor to one or more Affiliates. bettorAddress returns array of revShares
	mapping(address => revShare[]) bettorAffiliate;

	// Relate bettorAddress to revSharePool (affiliateAddress)
	mapping(address => address[]) revSharePool;

	// New Bettor Affiliate
	function newBettorAffiliate(address _bettorAddress, address _revSharePool, uint64 _percent) external returns (uint256, uint256) {	// Anyone can call this

	// Cannot be called if escrowAllowed
	// DISBALED as there is no escrowAllowed function in the XFUN Token Contract
	//	require(!tokenContract.escrowAllowed(_bettorAddress) && _bettorAddress != address(0) && _revSharePool != address(0));																			// But not if escrowAllowed
		require(_bettorAddress != address(0) && _revSharePool != address(0));																			// But not if escrowAllowed

		bettorAffiliate[_bettorAddress].push(revShare({revSharePool: _revSharePool, percent: _percent}));
		uint256 arr_index = bettorAffiliate[_bettorAddress].length -1;

		revSharePool[_revSharePool].push(_bettorAddress);
		uint256 arr_index_2 = revSharePool[_revSharePool].length;
	
		emit NewBettorAffiliate(_bettorAddress, arr_index, _revSharePool, _percent, arr_index_2);

		return(arr_index, arr_index_2);
	}

	function getRevSharePoolLength(address _revSharePool) external view returns (uint256) {
		return revSharePool[_revSharePool].length;
	}
	
	function getRevSharePoolBettor(address _revSharePool, uint256 _index) external view returns (address) {
		return revSharePool[_revSharePool][_index];
	}

	// Getters
	function getBettorAffiliateLength(address _bettorAddress) external view returns (uint256) {
		return bettorAffiliate[_bettorAddress].length;
	}

	function getBettorAffiliateRevSharePool(address _bettorAddress, uint256 _index) external view returns (address) {
		return bettorAffiliate[_bettorAddress][_index].revSharePool;
	}

	function getBettorAffiliatePercent(address _bettorAddress, uint256 _index) external view returns (uint64) {
		return bettorAffiliate[_bettorAddress][_index].percent;
	}

	// Calculate total % - should be 100% == 10000000000
	function getBettorAffiliateTotalPercent(address _bettorAddress) external view returns (uint64) {

		uint64 totalPercent = 0;

		for (uint256 i = 0; i < bettorAffiliate[_bettorAddress].length; i++) {
			totalPercent = uint64(totalPercent + bettorAffiliate[_bettorAddress][i].percent);  //need uint64 conversion as safemath returns uin256..
		}
		return totalPercent;
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

interface IXFUNToken {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Paused(address account);
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Unpaused(address account);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function MINTER_ROLE() external view returns (bytes32);

    function PAUSER_ROLE() external view returns (bytes32);

    function allowEscrow(address _escrow) external;

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function allowedEscrows(address) external view returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function disableEscrow(address _escrow) external;

    function enableEscrow(address _escrow) external;

    function escrowFrom(address _from, uint256 _value) external returns (bool);

    function escrowReturn(
        address _to,
        uint256 _value,
        uint256 _fee
    ) external returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantMinter(address _minter) external;

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function initialize(
        string memory name,
        string memory symbol,
        address _trustedForwarder
    ) external;

    function isTrustedForwarder(address forwarder) external view returns (bool);

    function mint(address to, uint256 amount) external;

    function name() external view returns (string memory);

    function pause() external;

    function paused() external view returns (bool);

    function removeEscrow(address _escrow) external;

    function renounceRole(bytes32 role, address account) external;

    function revokeMinter(address _minter) external;

    function revokeRole(bytes32 role, address account) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function trustedForwarder() external view returns (address);

    function unpause() external;

    function userAllowedEscrows(address, address) external view returns (bool);

    function versionRecipient() external view returns (string memory);

    function setTestVariable() external;

    function setTrustedForwarder(address _trustedForwarder) external;

    function version() external pure returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

interface IBetrRevShares {
    // Rev Share Deal struct, For GSP and Affilate deals
	struct revShare {
		address 	revSharePool;  	// Where to send the revenue share amount
		uint64 		percent;		// Commission - How much to take
	}

    event NewBettorAffiliate(
        address _bettorAddress,
        uint256 _index,
        address _revSharePool,
        uint64 _percent,
        uint256 _index2
    );
    event UpdateLayerAffiliatePercent(uint64 _percent);
    event UpdateResultorGSP(
        address _resultorAddress,
        address _revSharePool,
        uint64 _percent
    );

    function layerAffiliatePercent() external view returns (uint64);

    // function tokenContract() external view returns (address);

    function updateLayerAffiliatePercent(uint64 _percent) external;

    function updateResultorGSP(
        address _resultorAddress,
        address _revSharePool,
        uint64 _percent
    ) external;

    function getResultorGSPRevSharePool(address _resultorAddress)
        external
        view
        returns (address);

    function getResultorGSPPercent(address _resultorAddress)
        external
        view
        returns (uint64);

    function newBettorAffiliate(
        address _bettorAddress,
        address _revSharePool,
        uint64 _percent
    ) external returns (uint256, uint256);

    function getRevSharePoolLength(address _revSharePool)
        external
        view
        returns (uint256);

    function getRevSharePoolBettor(address _revSharePool, uint256 _index)
        external
        view
        returns (address);

    function getBettorAffiliateLength(address _bettorAddress)
        external
        view
        returns (uint256);

    function getBettorAffiliateRevSharePool(
        address _bettorAddress,
        uint256 _index
    ) external view returns (address);

    function getBettorAffiliatePercent(address _bettorAddress, uint256 _index)
        external
        view
        returns (uint64);

    function getBettorAffiliateTotalPercent(address _bettorAddress)
        external
        view
        returns (uint64);
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