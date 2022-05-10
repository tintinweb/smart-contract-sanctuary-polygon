pragma solidity 0.8.11;

import "./dependencies/Ownable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/solidly/IVotingEscrow.sol";
import "./interfaces/solidly/IBaseV1Minter.sol";
import "./interfaces/dextopia/IDextopiaToken.sol";


contract TopiaPartners is Ownable {

    IVotingEscrow public immutable votingEscrow;
    IBaseV1Minter public immutable solidMinter;

    IERC20 public VeTopia;
    IDextopiaToken public TOPIA;
    uint256 public tokenID;

    // current number of early TOPIA partners
    uint256 public partnerCount;
    // timestamp after which new TOPIA partners receive a reduced
    // amount of TOPIA in perpetuity (1 day prior to SOLID emissions starting)
    uint256 public earlyPartnerDeadline;
    // timestamp after which new TOPIA partners are no longer accepted
    uint256 public finalPartnerDeadline;

    // number of tokens that have been minted via this contract
    uint256 public totalMinted;
    // total % of the total supply that this contract is entitled to mint
    uint256 public totalMintPct;

    struct UserWeight {
        uint256 tranche;
        uint256 weight;
        uint256 claimed;
    }

    struct Tranche {
        uint256 minted;
        uint256 weight;
        uint256 mintPct;
    }

    // partners, vests
    Tranche[2] public trancheData;

    mapping (address => UserWeight) public userData;
    mapping (address => bool) public isEarlyPartner;

    // maximum number of TOPIA partners
    uint256 public constant MAX_PARTNER_COUNT = 20;

    address private treasary;

    constructor(
        IVotingEscrow _votingEscrow,
        IBaseV1Minter _minter,
        address[] memory _receivers,
        uint256[] memory _weights,
        address _treasary
    ) {
        votingEscrow = _votingEscrow;
        solidMinter = _minter;

        uint256 totalWeight;
        require(_receivers.length == _weights.length);
        for (uint i = 0; i < _receivers.length; i++) {
            totalWeight += _weights[i];
            // set claimed to 1 to avoid initial claim requirement for vestees calling `claim`
            userData[_receivers[i]] = UserWeight({tranche: 1, weight: _weights[i], claimed: 1});
        }

        trancheData[1].weight = totalWeight;
        trancheData[1].mintPct = 20;
        totalMintPct = 20;
        treasary = _treasary;
    }

    function changeTresary(address _treasary) external {
        require(msg.sender == treasary,"dextopia:you are not the tresary");
        treasary = _treasary;
    }

    function setAddresses(IERC20 _vetopia, IDextopiaToken _topia) external onlyOwner {
        VeTopia = _vetopia;
        TOPIA = _topia;

        renounceOwnership();
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenID,
        bytes calldata
    ) external returns (bytes4) {
        UserWeight storage u = userData[_operator];
        require(u.tranche == 0, "Conflict of interest!");
        require(u.weight == 0, "Already a partner");
        require(partnerCount < MAX_PARTNER_COUNT, "No more TOPIA partners allowed!");
        (uint256 amount,) = votingEscrow.locked(_tokenID);

        if (tokenID == 0) {
            // when receiving the first NFT, track the tokenID and set the partnership deadlines
            tokenID = _tokenID;
            earlyPartnerDeadline = solidMinter.activePeriod() + 86400 * 6;
            finalPartnerDeadline = earlyPartnerDeadline + 86400 * 14;
            isEarlyPartner[_operator] = true;

        } else if (block.timestamp < earlyPartnerDeadline) {
            // subsequent NFTs received before the early deadline are merged with the first
            votingEscrow.merge(_tokenID, tokenID);
            isEarlyPartner[_operator] = true;

        } else if (block.timestamp < finalPartnerDeadline) {
            require(_tokenID < 26, "Only early protocol NFTs are eligible");
            require(address(VeTopia) != address(0), "Addresses not set");

            // NFTs received after the early deadline are immediately converted to VeTopia
            votingEscrow.safeTransferFrom(address(this), address(VeTopia), _tokenID);
            VeTopia.transfer(_operator, amount);

            // TOPIA advance has a 50% immediate penalty and a linear decay to zero over 2 weeks
            amount = amount / 2 * (finalPartnerDeadline - block.timestamp) / (86400 * 14);
            uint256 advance = amount / 10;
            TOPIA.mint(_operator, advance * 99/100);
            TOPIA.mint(treasary,advance * 1/100);
            u.claimed = advance;
            trancheData[0].minted += advance;
            totalMinted += advance;

        } else revert("TOPIA in perpetuity no longer available");

        u.weight += amount;
        trancheData[0].weight += amount;
        partnerCount += 1;

        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function earlyPartnerPct() public view returns (uint256) {
        if (partnerCount < 11) return 10;
        return partnerCount;
    }

    function claimable(address account) external view returns (uint256) {
        if (block.timestamp <= finalPartnerDeadline) return 0;
        UserWeight storage u = userData[account];
        Tranche memory t = trancheData[u.tranche];

        uint256 _totalMintPct = totalMintPct;
        if (trancheData[0].mintPct == 0) {
            _totalMintPct += earlyPartnerPct();
            if (u.tranche == 0) t.mintPct = earlyPartnerPct();
        }

        uint256 supply = TOPIA.totalSupply() - totalMinted;
        uint256 mintable = (supply * 100 / (100 - _totalMintPct) - supply) * t.mintPct / _totalMintPct;
        if (mintable < t.minted) mintable = t.minted;

        uint256 totalClaimable = mintable * u.weight / t.weight;
        if (totalClaimable < u.claimed) return 0;
        return totalClaimable - u.claimed;

    }

    function claim() external returns (uint256) {
        UserWeight storage u = userData[msg.sender];
        Tranche storage t = trancheData[u.tranche];

        require(u.weight > 0, "Not a TOPIA partner");
        require(u.claimed > 0, "Must make initial claim first");
        require(block.timestamp > finalPartnerDeadline, "Cannot claim yet");

        if (trancheData[0].mintPct == 0) {
            trancheData[0].mintPct = earlyPartnerPct();
            totalMintPct += trancheData[0].mintPct;
        }

        // mint new TOPIA based on supply that was minted via regular emissions
        uint256 supply = TOPIA.totalSupply() - totalMinted;
        uint256 mintable = (supply * 100 / (100 - totalMintPct) - supply) * t.mintPct / totalMintPct;
        if (mintable > t.minted) {
            uint256 amount = mintable - t.minted;
            TOPIA.mint(address(this), amount * 99/100);
            TOPIA.mint(treasary,amount * 1/100);
            t.minted = mintable;
            totalMinted += amount;
        }

        uint256 totalClaimable = t.minted * u.weight / t.weight;
        if (totalClaimable > u.claimed) {
            uint256 amount = totalClaimable - u.claimed;
            TOPIA.transfer(msg.sender, amount);
            u.claimed = totalClaimable;
            return amount;
        }
        return 0;

    }

    function earlyPartnerClaim() external returns (uint256) {
        require(block.timestamp > earlyPartnerDeadline, "Cannot claim yet");
        require(owner == address(0), "Addresses not set");
        UserWeight storage u = userData[msg.sender];
        require(u.tranche == 0 && u.weight > 0, "Not a TOPIA partner");
        require(u.claimed == 0, "TOPIA advance already claimed");
        Tranche storage t = trancheData[0];

        if (votingEscrow.ownerOf(tokenID) == address(this)) {
            // transfer the NFT to mint early partner VeTopia
            votingEscrow.safeTransferFrom(address(this), address(VeTopia), tokenID);
        }

        // transfer owed VeTopia
        uint256 amount = u.weight;
        VeTopia.transfer(msg.sender, amount);

        // mint TOPIA advance
        amount /= 10;
        u.claimed = amount;
        t.minted += amount;
        totalMinted += amount;
        TOPIA.mint(msg.sender, amount * 99/100);
        TOPIA.mint(treasary,amount * 1/100);

        return amount;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
abstract contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
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
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

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
}

pragma solidity 0.8.11;

interface IVotingEscrow {
    function increaseAmount(uint256 tokenID, uint256 value) external;
    function increaseUnlockTime(uint256 tokenID, uint256 duration) external;
    function merge(uint256 fromID, uint256 toID) external;
    function locked(uint256 tokenID) external view returns (uint256 amount, uint256 unlockTime);
    function setApprovalForAll(address operator, bool approved) external;
    function transferFrom(address from, address to, uint256 tokenID) external;
    function safeTransferFrom(address from, address to, uint tokenId) external;
    function ownerOf(uint tokenId) external view returns (address);
    function balanceOfNFT(uint tokenId) external view returns (uint);
    function isApprovedOrOwner(address, uint) external view returns (bool);
}

pragma solidity 0.8.11;

interface IBaseV1Minter {
    function activePeriod() external view returns (uint256);
}

pragma solidity 0.8.11;

import "../IERC20.sol";

interface IDextopiaToken is IERC20 {
    function mint(address _to, uint256 _value) external returns (bool);
}