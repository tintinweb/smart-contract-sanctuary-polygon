// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IVCPool.sol";
import "../interfaces/IVCStarter.sol";
import "../interfaces/IPoCNft.sol";
import "../interfaces/IMarketplaceFixedPrice.sol";
import "../interfaces/IMarketplaceAuction.sol";
import "../interfaces/IArtNft.sol";

contract VCGovernance {
    error GovNotWhitelistedLab();
    error GovOnlyAdmin();
    error GovInvalidAdmin();
    error GovInvalidQuorumPoll();

    event ProtocolSetup(
        address indexed vcPool,
        address indexed vcStarter,
        IERC20 currency,
        address marketplaceFixedPrice1155,
        address marketplaceFixedPrice721,
        address marketplaceAuction721,
        address artNft1155,
        address artNft721,
        address pocNft
    );

    address public admin;
    IERC20 public currency;
    IERC20 public cure;
    IVCPool public pool;
    IVCStarter public starter;
    // FIXME: checar estas interfaces de los marketplace
    IMarketplaceFixedPrice public marketplaceFixedPrice1155;
    IMarketplaceFixedPrice public marketplaceFixedPrice721;
    IMarketplaceAuction public marketplaceAuction1155;
    IMarketplaceAuction public marketplaceAuction721;
    // FIXME: checar las interfaces de los ArtNft
    IArtNft public artNft1155;
    IArtNft public artNft721;
    IPoCNft public pocNft;

    mapping(address => bool) public isWhitelistedLab;

    constructor(IERC20 _cure, address _admin) {
        _setAdmin(_admin);
        cure = _cure;
    }

    modifier onlyWhitelistedLab(address _lab) {
        if (!isWhitelistedLab[_lab]) {
            revert GovNotWhitelistedLab();
        }
        _;
    }

    function _onlyAdmin() private view {
        if (msg.sender != admin) {
            revert GovOnlyAdmin();
        }
    }

    function setupProtocol(
        IERC20 _currency,
        address _vcPool,
        address _vcStarter,
        address _marketplaceFixedPrice1155,
        address _marketplaceFixedPrice721,
        address _marketplaceAuction1155,
        address _marketplaceAuction721,
        address _artNft1155,
        address _artNft721,
        address _pocNft
    ) external {
        _onlyAdmin();

        pool = IVCPool(_vcPool);
        starter = IVCStarter(_vcStarter);
        marketplaceFixedPrice1155 = IMarketplaceFixedPrice(_marketplaceFixedPrice1155);
        marketplaceFixedPrice721 = IMarketplaceFixedPrice(_marketplaceFixedPrice721);
        marketplaceAuction1155 = IMarketplaceAuction(_marketplaceAuction1155);
        marketplaceAuction721 = IMarketplaceAuction(_marketplaceAuction721);
        artNft1155 = IArtNft(_artNft1155);
        artNft721 = IArtNft(_artNft721);
        pocNft = IPoCNft(_pocNft);

        _setPoCNft(_pocNft);
        _setCurrency(_currency);
        _setMinterRoleArtNft(_marketplaceFixedPrice1155);
        _setMinterRoleArtNft(_marketplaceFixedPrice721);
        _setMinterRoleArtNft(_marketplaceAuction1155);
        _setMinterRoleArtNft(_marketplaceAuction721);

        emit ProtocolSetup(
            _vcPool,
            _vcStarter,
            _currency,
            _marketplaceFixedPrice1155,
            _marketplaceFixedPrice721,
            _marketplaceAuction721,
            _artNft1155,
            _artNft721,
            _pocNft
        );
    }

    function setAdmin(address _newAdmin) external {
        _onlyAdmin();
        _setAdmin(_newAdmin);
    }

    function _setAdmin(address _newAdmin) private {
        if (_newAdmin == address(0) || _newAdmin == admin) {
            revert GovInvalidAdmin();
        }
        admin = _newAdmin;
    }

    function marketplaceFixedPrice1155WithdrawTo(
        address _token,
        address _to,
        uint256 _amount
    ) external {
        _onlyAdmin();
        marketplaceFixedPrice1155.withdrawTo(_token, _to, _amount);
    }

    function marketplaceFixedPrice721WithdrawTo(
        address _token,
        address _to,
        uint256 _amount
    ) external {
        _onlyAdmin();
        marketplaceFixedPrice721.withdrawTo(_token, _to, _amount);
    }

    function marketplaceAuction721WithdrawTo(
        address _token,
        address _to,
        uint256 _amount
    ) external {
        _onlyAdmin();
        marketplaceAuction721.withdrawTo(_token, _to, _amount);
    }

    function _setPoCNft(address _pocNft) internal {
        _onlyAdmin();
        pool.setPoCNft(_pocNft);
        starter.setPoCNft(_pocNft);
        marketplaceFixedPrice1155.setPoCNft(_pocNft);
        marketplaceFixedPrice721.setPoCNft(_pocNft);
        marketplaceAuction1155.setPoCNft(_pocNft);
        marketplaceAuction721.setPoCNft(_pocNft);
    }

    //////////////////////////////////////////
    // MARKETPLACE SETUP THROUGH GOVERNANCE //
    //////////////////////////////////////////

    // FIXME: I think we should delete this functions
    // function whitelistTokens(address[] memory _tokens) external {
    //     _onlyAdmin();
    //     marketplaceFixedPrice1155.whitelistTokens(_tokens);
    //     marketplaceFixedPrice721.whitelistTokens(_tokens);
    //     marketplaceAuction721.whitelistTokens(_tokens);
    // }

    // function blacklistTokens(address[] memory _tokens) external {
    //     _onlyAdmin();
    //     marketplaceFixedPrice1155.blacklistTokens(_tokens);
    //     marketplaceFixedPrice721.blacklistTokens(_tokens);
    //     marketplaceAuction721.blacklistTokens(_tokens);
    // }

    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) external {
        _onlyAdmin();
        marketplaceFixedPrice1155.setMaxBeneficiaryProjects(_maxBeneficiaryProjects);
        marketplaceFixedPrice721.setMaxBeneficiaryProjects(_maxBeneficiaryProjects);
        marketplaceAuction721.setMaxBeneficiaryProjects(_maxBeneficiaryProjects);
    }

    function setMinTotalFeeBps(uint96 _minTotalFeeBps) external {
        _onlyAdmin();
        marketplaceFixedPrice1155.setMinTotalFeeBps(_minTotalFeeBps);
        marketplaceFixedPrice721.setMinTotalFeeBps(_minTotalFeeBps);
        marketplaceAuction721.setMinTotalFeeBps(_minTotalFeeBps);
    }

    function setMarketplaceFee(uint256 _marketplaceFee) external {
        _onlyAdmin();
        marketplaceFixedPrice1155.setMarketplaceFee(_marketplaceFee);
        marketplaceFixedPrice721.setMarketplaceFee(_marketplaceFee);
        marketplaceAuction721.setMarketplaceFee(_marketplaceFee);
    }

    /////////////////////////////////////////
    // ART NFT SETUP THROUGH GOVERNANCE    //
    /////////////////////////////////////////

    function setMinterRoleArtNft(address _minter) external {
        _onlyAdmin();
        _setMinterRoleArtNft(_minter);
    }

    function _setMinterRoleArtNft(address _marketplace) private {
        artNft1155.grantMinterRole(_marketplace);
        artNft721.grantMinterRole(_marketplace);
    }

    function setRoyaltyInfoArtNft(address _receiver, uint96 _royaltyFeeBps) external {
        _onlyAdmin();
        artNft1155.setRoyaltyInfo(_receiver, _royaltyFeeBps);
        artNft721.setRoyaltyInfo(_receiver, _royaltyFeeBps);
    }

    function setMaxRoyalty(uint256 _maxRoyaltyBps) external {
        _onlyAdmin();
        artNft1155.setMaxRoyalty(_maxRoyaltyBps);
        artNft721.setMaxRoyalty(_maxRoyaltyBps);
    }

    function setMaxBatchSize(uint256 _maxBatchSize) external {
        _onlyAdmin();
        artNft1155.setMaxBatchSize(_maxBatchSize);
        artNft721.setMaxBatchSize(_maxBatchSize);
    }

    /*
// LO COMENTO PORQUE addCreator ya no existe
    function grantCreatorRoleArtNft(address _newCreator) external {
        _onlyAdmin();
        artNft.addCreator(_newCreator);
    }
*/
    //////////////////////////////////////
    // STARTER SETUP THROUGH GOVERNANCE //
    //////////////////////////////////////

    function setMarketplaceFixedPriceStarter(address _newMarketplaceFixedPrice) external {
        _onlyAdmin();
        starter.setMarketplaceFixedPrice(_newMarketplaceFixedPrice);
    }

    function setMarketplaceAuctionStarter(address _newMarketplaceAuction) external {
        _onlyAdmin();
        starter.setMarketplaceAuction(_newMarketplaceAuction);
    }

    // NECESITAMOS UN BLACKLIST O UN REMOVE WHITELIST??
    function whitelistLabsStarter(address[] memory _labs) external {
        _onlyAdmin();
        starter.whitelistLabs(_labs);
    }

    function setQuorumPollStarter(uint256 _quorumPoll) external {
        _onlyAdmin();
        if (_quorumPoll > 100) {
            revert GovInvalidQuorumPoll();
        }
        starter.setQuorumPoll(_quorumPoll);
    }

    function setMaxPollDurationStarter(uint256 _maxPollDuration) external {
        // should we check something here??
        _onlyAdmin();
        starter.setMaxPollDuration(_maxPollDuration);
    }

    ////////////////
    // GOVERNANCE //
    ////////////////

    function votePower(address _account) external view returns (uint256 userVotePower) {
        uint256 userCureBalance = cure.balanceOf(_account);
        uint256 boost = pocNft.getVotingPowerBoost(_account);

        userVotePower = (userCureBalance * (10000 + boost)) / 10000;
    }

    function setCurrency(IERC20 _currency) external {
        _onlyAdmin();
        _setCurrency(_currency);
    }

    function _setCurrency(IERC20 _currency) private {
        currency = _currency;
        starter.setCurrency(_currency);
        pool.setCurrency(_currency);
        marketplaceFixedPrice1155.setCurrency(_currency);
        marketplaceFixedPrice721.setCurrency(_currency);
        marketplaceAuction1155.setCurrency(_currency);
        marketplaceAuction721.setCurrency(_currency);
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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVCPool {
    function setPoCNft(address _poolNFT) external;

    function setCurrency(IERC20 _currency) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVCStarter {
    function currency() external returns (IERC20);

    function setPoCNft(address _poCNFT) external;

    function setMarketplaceAuction(address _newMarketplace) external;

    function setMarketplaceFixedPrice(address _newMarketplace) external;

    function whitelistLabs(address[] memory _labs) external;

    function setCurrency(IERC20 _currency) external;

    function setQuorumPoll(uint256 _quorumPoll) external;

    function setMaxPollDuration(uint256 _maxPollDuration) external;

    function maxPollDuration() external view returns (uint256);

    function fundProjectFromMarketplace(uint256 _projectId, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPoCNft {
    function mint(address _user, uint256 _amount) external;

    function getVotingPowerBoost(address _user) external view returns (uint256 votingPowerBoost);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IArtNft.sol";

interface IMarketplaceAuction {
    function whitelistTokens(address[] memory _tokens) external;

    function blacklistTokens(address[] memory _tokens) external;

    function withdrawTo(
        address _token,
        address _to,
        uint256 _amount
    ) external;

    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) external;

    function setMinTotalFeeBps(uint96 _minTotalFeeBps) external;

    function setMarketplaceFee(uint256 _marketplaceFee) external;

    function calculateMarketplaceFee(uint256 _price) external;

    function setPoCNft(address _pocNft) external;

    function setCurrency(IERC20 _currency) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IArtNft.sol";

interface IMarketplaceFixedPrice {
    function whitelistTokens(address[] memory _tokens) external;

    function blacklistTokens(address[] memory _tokens) external;

    function withdrawTo(
        address _token,
        address _to,
        uint256 _amount
    ) external;

    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) external;

    function setMinTotalFeeBps(uint96 _minTotalFeeBps) external;

    function setMarketplaceFee(uint256 _marketplaceFee) external;

    function calculateMarketplaceFee(uint256 _price) external;

    function setPoCNft(address _pocNft) external;

    function setCurrency(IERC20 _currency) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IArtNft {
    function exists(uint256 _tokenId) external returns (bool);

    function grantMinterRole(address _address) external;

    function setMaxRoyalty(uint256 _maxRoyaltyBps) external;

    function setMaxBatchSize(uint256 _maxBatchSize) external;

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeeBps) external;
}