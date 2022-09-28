// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// import "hardhat/console.sol";
import "./InterPlanetaryFontNFT.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISuperfluid, ISuperToken} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";
import { ISETH } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/tokens/ISETH.sol";
import {IInstantDistributionAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IInstantDistributionAgreementV1.sol";

import {IDAv1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/IDAv1Library.sol";

contract FontProject {
  InterPlanetaryFontNFT private fontNFT = new InterPlanetaryFontNFT();

  uint8 constant TOTAL_DISTRIBUTION_UNITS = 100;
  uint8 constant OWNER_DISTRIBUTION_UNITS = 60;
  uint8 constant COLLABORATOR_DISTRIBUTION_UNITS = TOTAL_DISTRIBUTION_UNITS - OWNER_DISTRIBUTION_UNITS;

  // address constant MATIC_MUMBAI_CONTRACT = 0x0000000000000000000000000000000000001010;
  // address constant MATICX_MUMBAI_CONTRACT = 0x96B82B65ACF7072eFEb00502F45757F254c2a0D4;

  /// @notice IDA Library
  using IDAv1Library for IDAv1Library.InitData;
  IDAv1Library.InitData internal _idaV1;
  address private superToken;
  
  mapping(bytes32 => CreateFontProject) public idToFontProject;

  uint32 private currentIDAIndex = 0;

  constructor(ISuperfluid _host, IInstantDistributionAgreementV1 _ida, address _superToken) {

    // IDA Library Initialize.
    _idaV1 = IDAv1Library.InitData(
        _host,
        _ida
    );

    superToken = _superToken;
  }

  event NewFontProjectCreated(
    bytes32 fontId,
    string metaDataCID,
    address creatorAddress,
    uint256 mintPrice,
    uint256 createdAt,
    uint256 startDateTime
  );

  event FontProjectMinted(
    bytes32 fontId,
    uint256 tokenId
  );

  struct CreateFontProject {
    bytes32 id;
    string metaDataCID;
    address creatorAddress;
    uint256 mintPrice;
    uint256[] mints;
    address[] collaborators;

    ISuperToken idaDistributionToken;
    uint32 royaltyIDAIndex;
    // uint256[] fundingStreamIds; TBD

    uint256 createdAt;
    uint256 startDateTime;
  }

  function createNewFontProject(
    uint256 createdAt,
    uint256 startDateTime,
    uint256 mintPrice,
    string calldata metaDataCID
  ) external {
    bytes32 fontId = keccak256(
        abi.encodePacked(
            msg.sender,
            address(this),
            createdAt,
            startDateTime,
            mintPrice
        )
    );

    require(idToFontProject[fontId].startDateTime == 0, "FONT IS ALREADY REGISTERED");

    uint256[] memory mints;
    address[] memory collaborators;

    currentIDAIndex = currentIDAIndex + 1;

    ISuperToken idaDistributionToken = ISuperToken(superToken);

    CreateFontProject memory font = CreateFontProject(
        fontId,
        metaDataCID,
        msg.sender,
        mintPrice,
        mints,
        collaborators,
        idaDistributionToken,
        currentIDAIndex,
        createdAt,
        startDateTime
    );
    idToFontProject[fontId] = font;

    _idaV1.createIndex(
      font.idaDistributionToken,
      font.royaltyIDAIndex
    );

    _idaV1.updateSubscriptionUnits(
      font.idaDistributionToken,
      font.royaltyIDAIndex,
      msg.sender,
      1
    );

    emit NewFontProjectCreated(
      fontId,
      metaDataCID, 
      msg.sender,
      mintPrice, 
      createdAt,
      startDateTime
    );
  }

  function addCollaborator(bytes32 fontId, address collaborator) external {
    CreateFontProject storage font = idToFontProject[fontId];

    require(font.startDateTime != 0, "FONT NOT FOUND");
    require(font.creatorAddress == msg.sender, "ONLY FONT CREATOR CAN UPDATE COLLABORATORS");
    require(!contains(font.collaborators, collaborator), "ALREADY A COLLABORATOR");

    font.collaborators.push(collaborator);

    setFontCollaboratorProfitDistribution(font.id, COLLABORATOR_DISTRIBUTION_UNITS);
  }


  function mintFontProject(
    bytes32 fontId,
    string memory uri
  ) external payable {
    CreateFontProject storage font = idToFontProject[fontId];

    require(font.startDateTime != 0, "FONT NOT FOUND");
    require(msg.value == font.mintPrice, "NOT ENOUGH ETH SENT");


    ISETH(superToken).upgradeByETHTo{ value : msg.value }(address(this));
    // console.log("Contract Super ETH Balance", ISuperToken(superToken).balanceOf(address(this)));
    // console.log("Contract Regular Balance", address(this).balance);
    
    uint256 tokenId = fontNFT.safeMint(msg.sender, uri);
    font.mints.push(tokenId);

    distributeFontProfit(fontId);

    emit FontProjectMinted(
      fontId,
      tokenId
    );
  }

  function contains(address[] memory arr, address searchFor) private pure returns (bool) {
    for (uint256 i = 0; i < arr.length; i++) {
      if (arr[i] == searchFor) {
        return true;
      }
    }
    return false;
  }

  function setFontCollaboratorProfitDistribution(bytes32 fontId, uint128 distributionUnits) private {
    CreateFontProject memory font = idToFontProject[fontId];

    require(font.startDateTime != 0, "FONT NOT FOUND");
    require(font.creatorAddress == msg.sender, "ONLY FONT CREATOR CAN UPDATE COLLABORATOR PROFIT DISTRIBUTION");

    uint128 perCollaboratorDistributionUnits = uint128(distributionUnits / font.collaborators.length);

    for (uint256 i = 0; i < font.collaborators.length; i++) {
      _idaV1.updateSubscriptionUnits(
        font.idaDistributionToken,
        font.royaltyIDAIndex,
        font.collaborators[i],
        perCollaboratorDistributionUnits
      );
    }
  }

  function distributeFontProfit(bytes32 fontId) public {
    CreateFontProject memory font = idToFontProject[fontId];

    require(font.startDateTime != 0, "FONT NOT FOUND");

    uint256 spreaderTokenBalance = font.idaDistributionToken.balanceOf(address(this));

    // console.log("spreaderTokenBalance", spreaderTokenBalance);

    (uint256 actualDistributionAmount, ) = _idaV1.ida.calculateDistribution(
        font.idaDistributionToken,
        address(this),
        font.royaltyIDAIndex,
        spreaderTokenBalance
    );

    _idaV1.distribute(font.idaDistributionToken, font.royaltyIDAIndex, actualDistributionAmount);

    // console.log("Contract SETH balance after distribution", ISuperToken(superToken).balanceOf(address(this)));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract InterPlanetaryFontNFT is ERC721, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("InterPlanetaryFontNFT", "IPF") {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, string memory uri) public returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        return tokenId;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.0;

import {
    ISuperfluid,
    ISuperToken,
    ISuperApp,
    SuperAppDefinitions
} from "../interfaces/superfluid/ISuperfluid.sol";

abstract contract SuperAppBase is ISuperApp {

    function beforeAgreementCreated(
        ISuperToken /*superToken*/,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata /*ctx*/
    )
        external
        view
        virtual
        override
        returns (bytes memory /*cbdata*/)
    {
        revert("Unsupported callback - Before Agreement Created");
    }

    function afterAgreementCreated(
        ISuperToken /*superToken*/,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata /*cbdata*/,
        bytes calldata /*ctx*/
    )
        external
        virtual
        override
        returns (bytes memory /*newCtx*/)
    {
        revert("Unsupported callback - After Agreement Created");
    }

    function beforeAgreementUpdated(
        ISuperToken /*superToken*/,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata /*ctx*/
    )
        external
        view
        virtual
        override
        returns (bytes memory /*cbdata*/)
    {
        revert("Unsupported callback - Before Agreement updated");
    }

    function afterAgreementUpdated(
        ISuperToken /*superToken*/,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata /*cbdata*/,
        bytes calldata /*ctx*/
    )
        external
        virtual
        override
        returns (bytes memory /*newCtx*/)
    {
        revert("Unsupported callback - After Agreement Updated");
    }

    function beforeAgreementTerminated(
        ISuperToken /*superToken*/,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata /*ctx*/
    )
        external
        view
        virtual
        override
        returns (bytes memory /*cbdata*/)
    {
        revert("Unsupported callback -  Before Agreement Terminated");
    }

    function afterAgreementTerminated(
        ISuperToken /*superToken*/,
        address /*agreementClass*/,
        bytes32 /*agreementId*/,
        bytes calldata /*agreementData*/,
        bytes calldata /*cbdata*/,
        bytes calldata /*ctx*/
    )
        external
        virtual
        override
        returns (bytes memory /*newCtx*/)
    {
        revert("Unsupported callback - After Agreement Terminated");
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

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.0;
pragma experimental ABIEncoderV2;

import {ISuperfluid, ISuperfluidToken} from "../interfaces/superfluid/ISuperfluid.sol";

import {
    IInstantDistributionAgreementV1
} from "../interfaces/agreements/IInstantDistributionAgreementV1.sol";

/// @title Instant Distribution Agreement V1 helper library for solidity development.
/// @author Superfluid
/// @dev Set a variable of type `InitData` in the contract, then call this library's functions
/// directly `initData.functionName()`.
library IDAv1Library {

    /// @dev Initialization data.
    /// @param host Superfluid host contract for calling agreements.
    /// @param ida Instant Distribution Agreement contract.
    struct InitData {
        ISuperfluid host;
        IInstantDistributionAgreementV1 ida;
    }

    /**************************************************************************
     * View Functions
     *************************************************************************/

    /// @dev Gets an index by its ID and publisher.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param token Super token used with the index.
    /// @param publisher Publisher of the index.
    /// @param indexId ID of the index.
    /// @return exist True if the index exists.
    /// @return indexValue Total value of the index.
    /// @return totalUnitsApproved Units of the index approved by subscribers.
    /// @return totalUnitsPending Units of teh index not yet approved by subscribers.
    function getIndex(
        InitData storage idaLibrary,
        ISuperfluidToken token,
        address publisher,
        uint32 indexId
    )
        internal
        view
        returns (
            bool exist,
            uint128 indexValue,
            uint128 totalUnitsApproved,
            uint128 totalUnitsPending
        )
    {
        return idaLibrary.ida.getIndex(token, publisher, indexId);
    }

    /// @dev Calculates the distribution amount based on the amount of tokens desired to distribute.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param token Super token used with the index.
    /// @param publisher Publisher of the index.
    /// @param indexId ID of the index.
    /// @param amount Amount of tokens desired to distribute.
    /// @return actualAmount Amount to be distributed with correct rounding.
    /// @return newIndexValue The index value after the distribution would be called.
    function calculateDistribution(
        InitData storage idaLibrary,
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        uint256 amount
    )
        internal
        view
        returns (
            uint256 actualAmount,
            uint128 newIndexValue
        )
    {
        return idaLibrary.ida.calculateDistribution(token, publisher, indexId, amount);
    }

    /// @dev List all subscriptions of an address
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param token Super token used in the indexes listed.
    /// @param subscriber Subscriber address.
    /// @return publishers Publishers of the indices.
    /// @return indexIds IDs of the indices.
    /// @return unitsList Units owned of the indices.
    function listSubscriptions(
        InitData storage idaLibrary,
        ISuperfluidToken token,
        address subscriber
    )
        internal
        view
        returns (
            address[] memory publishers,
            uint32[] memory indexIds,
            uint128[] memory unitsList
        )
    {
        return idaLibrary.ida.listSubscriptions(token, subscriber);
    }

    /// @dev Gets subscription by publisher, index id, and subscriber.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param token Super token used with the index.
    /// @param publisher Publisher of the index.
    /// @param indexId ID of the index.
    /// @param subscriber Subscriber to the index.
    /// @return exist True if the subscription exists.
    /// @return approved True if the subscription has been approved by the subscriber.
    /// @return units Units held by the subscriber
    /// @return pendingDistribution If not approved, the amount to be claimed on approval.
    function getSubscription(
        InitData storage idaLibrary,
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        address subscriber
    )
        internal
        view
        returns (
            bool exist,
            bool approved,
            uint128 units,
            uint256 pendingDistribution
        )
    {
        return idaLibrary.ida.getSubscription(token, publisher, indexId, subscriber);
    }

    /// @dev Gets subscription by the agreement ID.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param token Super Token used with the index.
    /// @param agreementId Agreement ID, unique to the subscriber and index ID.
    /// @return publisher Publisher of the index.
    /// @return indexId ID of the index.
    /// @return approved True if the subscription has been approved by the subscriber.
    /// @return units Units held by the subscriber
    /// @return pendingDistribution If not approved, the amount to be claimed on approval.
    function getSubscriptionByID(
        InitData storage idaLibrary,
        ISuperfluidToken token,
        bytes32 agreementId
    )
        internal
        view
        returns (
            address publisher,
            uint32 indexId,
            bool approved,
            uint128 units,
            uint256 pendingDistribution
        )
    {
        return idaLibrary.ida.getSubscriptionByID(token, agreementId);
    }

    /**************************************************************************
     * Index Operations
     *************************************************************************/

    /// @dev Creates a new index.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param token Super Token used with the index.
    /// @param indexId ID of the index.
    function createIndex(
        InitData storage idaLibrary,
        ISuperfluidToken token,
        uint32 indexId
    ) internal {
        createIndex(idaLibrary, token, indexId, new bytes(0));
    }

    /// @dev Creates a new index. This takes arbitrary user data.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param token Super Token used with the index.
    /// @param indexId ID of the index.
    /// @param userData Arbitrary user data field.
    function createIndex(
        InitData storage idaLibrary,
        ISuperfluidToken token,
        uint32 indexId,
        bytes memory userData
    ) internal {
        idaLibrary.host.callAgreement(
            idaLibrary.ida,
            abi.encodeCall(
                idaLibrary.ida.createIndex,
                (
                    token,
                    indexId,
                    new bytes(0) // ctx placeholder
                )
            ),
            userData
        );
    }

    /// @dev Creates a new index in a super app callback.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param ctx Context byte string used by the Superfluid host.
    /// @param token Super Token used with the index.
    /// @param indexId ID of the index.
    function createIndexWithCtx(
        InitData storage idaLibrary,
        bytes memory ctx,
        ISuperfluidToken token,
        uint32 indexId
    ) internal returns (bytes memory newCtx) {
        return createIndexWithCtx(idaLibrary, ctx, token, indexId, new bytes(0));
    }

    /// @dev Creates a new index in a super app callback. This takes arbitrary user data.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param ctx Context byte string used by the Superfluid host.
    /// @param token Super Token used with the index.
    /// @param indexId ID of the index.
    /// @param userData Arbitrary user data field.
    function createIndexWithCtx(
        InitData storage idaLibrary,
        bytes memory ctx,
        ISuperfluidToken token,
        uint32 indexId,
        bytes memory userData
    ) internal returns (bytes memory newCtx) {
        (newCtx, ) = idaLibrary.host.callAgreementWithContext(
            idaLibrary.ida,
            abi.encodeCall(
                idaLibrary.ida.createIndex,
                (
                    token,
                    indexId,
                    new bytes(0) // ctx placeholder
                )
            ),
            userData,
            ctx
        );
    }

    /// @dev Updates an index value. This distributes an amount of tokens equal to
    /// `indexValue - lastIndexValue`. See `distribute` for another way to distribute. This takes
    /// arbitrary user data.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param token Super Token used with the index.
    /// @param indexId ID of the index.
    /// @param indexValue New TOTAL index value, this will equal the total amount distributed.
    function updateIndexValue(
        InitData storage idaLibrary,
        ISuperfluidToken token,
        uint32 indexId,
        uint128 indexValue
    ) internal {
        updateIndexValue(idaLibrary, token, indexId, indexValue, new bytes(0));
    }

    /// @dev Updates an index value. This distributes an amount of tokens equal to
    /// `indexValue - lastIndexValue`. See `distribute` for another way to distribute.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param token Super Token used with the index.
    /// @param indexId ID of the index.
    /// @param indexValue New TOTAL index value, this will equal the total amount distributed.
    /// @param userData Arbitrary user data field.
    function updateIndexValue(
        InitData storage idaLibrary,
        ISuperfluidToken token,
        uint32 indexId,
        uint128 indexValue,
        bytes memory userData
    ) internal {
        idaLibrary.host.callAgreement(
            idaLibrary.ida,
            abi.encodeCall(
                idaLibrary.ida.updateIndex,
                (
                    token,
                    indexId,
                    indexValue,
                    new bytes(0) // ctx placeholder
                )
            ),
            userData
        );
    }

    /// @dev Updates an index value in a super app callback. This distributes an amount of tokens
    /// equal to `indexValue - lastIndexValue`. See `distribute` for another way to distribute.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param ctx Context byte string used by the Superfluid host.
    /// @param token Super Token used with the index.
    /// @param indexId ID of the index.
    /// @param indexValue New TOTAL index value, this will equal the total amount distributed.
    function updateIndexValueWithCtx(
        InitData storage idaLibrary,
        bytes memory ctx,
        ISuperfluidToken token,
        uint32 indexId,
        uint128 indexValue
    ) internal returns (bytes memory newCtx) {
        return updateIndexValueWithCtx(
            idaLibrary,
            ctx,
            token,
            indexId,
            indexValue,
            new bytes(0)
        );
    }

    /// @dev Updates an index value in a super app callback. This distributes an amount of tokens
    /// equal to `indexValue - lastIndexValue`. See `distribute` for another way to distribute.
    /// This takes arbitrary user data.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param ctx Context byte string used by the Superfluid host.
    /// @param token Super Token used with the index.
    /// @param indexId ID of the index.
    /// @param indexValue New TOTAL index value, this will equal the total amount distributed.
    function updateIndexValueWithCtx(
        InitData storage idaLibrary,
        bytes memory ctx,
        ISuperfluidToken token,
        uint32 indexId,
        uint128 indexValue,
        bytes memory userData
    ) internal returns (bytes memory newCtx) {
        (newCtx, ) = idaLibrary.host.callAgreementWithContext(
            idaLibrary.ida,
            abi.encodeCall(
                idaLibrary.ida.updateIndex,
                (
                    token,
                    indexId,
                    indexValue,
                    new bytes(0) // ctx placeholder
                )
            ),
            userData,
            ctx
        );
    }

    /// @dev Distributes tokens in a more developer friendly way than `updateIndex`. Instead of
    /// passing the new total index value, this function will increase the index value by `amount`.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param token Super Token used with the index.
    /// @param indexId ID of the index.
    /// @param amount Amount by which the index value should increase.
    function distribute(
        InitData storage idaLibrary,
        ISuperfluidToken token,
        uint32 indexId,
        uint256 amount
    ) internal {
        distribute(idaLibrary, token, indexId, amount, new bytes(0));
    }

    /// @dev Distributes tokens in a more developer friendly way than `updateIndex`. Instead of
    /// passing the new total index value, this function will increase the index value by `amount`.
    /// This takes arbitrary user data.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param token Super Token used with the index.
    /// @param indexId ID of the index.
    /// @param amount Amount by which the index value should increase.
    /// @param userData Arbitrary user data field.
    function distribute(
        InitData storage idaLibrary,
        ISuperfluidToken token,
        uint32 indexId,
        uint256 amount,
        bytes memory userData
    ) internal {
        idaLibrary.host.callAgreement(
            idaLibrary.ida,
            abi.encodeCall(
                idaLibrary.ida.distribute,
                (
                    token,
                    indexId,
                    amount,
                    new bytes(0) // ctx placeholder
                )
            ),
            userData
        );
    }

    /// @dev Distributes tokens in a super app callback. Instead of passing the new total index
    /// value, this function will increase the index value by `amount`.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param ctx Context byte string used by the Superfluid host.
    /// @param token Super Token used with the index.
    /// @param indexId ID of the index.
    /// @param amount Amount by which the index value should increase.
    function distributeWithCtx(
        InitData storage idaLibrary,
        bytes memory ctx,
        ISuperfluidToken token,
        uint32 indexId,
        uint256 amount
    ) internal returns (bytes memory newCtx) {
        return distributeWithCtx(idaLibrary, ctx, token, indexId, amount, new bytes(0));
    }

    /// @dev Distributes tokens in a super app callback. Instead of passing the new total index
    /// value, this function will increase the index value by `amount`. This takes arbitrary user
    /// data.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param ctx Context byte string used by the Superfluid host.
    /// @param token Super Token used with the index.
    /// @param indexId ID of the index.
    /// @param amount Amount by which the index value should increase.
    /// @param userData Arbitrary user data field.
    function distributeWithCtx(
        InitData storage idaLibrary,
        bytes memory ctx,
        ISuperfluidToken token,
        uint32 indexId,
        uint256 amount,
        bytes memory userData
    ) internal returns (bytes memory newCtx) {
        (newCtx, ) = idaLibrary.host.callAgreementWithContext(
            idaLibrary.ida,
            abi.encodeCall(
                idaLibrary.ida.distribute,
                (
                    token,
                    indexId,
                    amount,
                    new bytes(0) // ctx placeholder
                )
            ),
            userData,
            ctx
        );
    }

    /**************************************************************************
     * Subscription Operations
     *************************************************************************/

    /// @dev Approves a subscription to an index. The subscriber's real time balance will not update
    /// until the subscription is approved, but once approved, the balance will be updated with
    /// prior distributions.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param token Super Token used with the index.
    /// @param publisher Publisher of the index.
    /// @param indexId ID of the index.
    function approveSubscription(
        InitData storage idaLibrary,
        ISuperfluidToken token,
        address publisher,
        uint32 indexId
    ) internal {
        approveSubscription(idaLibrary, token, publisher, indexId, new bytes(0));
    }

    /// @dev Approves a subscription to an index. The subscriber's real time balance will not update
    /// until the subscription is approved, but once approved, the balance will be updated with
    /// prior distributions.
    /// This takes arbitrary user data.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param token Super Token used with the index.
    /// @param publisher Publisher of the index.
    /// @param indexId ID of the index.
    /// @param userData Arbitrary user data field.
    function approveSubscription(
        InitData storage idaLibrary,
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        bytes memory userData
    ) internal {
        idaLibrary.host.callAgreement(
            idaLibrary.ida,
            abi.encodeCall(
                idaLibrary.ida.approveSubscription,
                (
                    token,
                    publisher,
                    indexId,
                    new bytes(0) // ctx placeholder
                )
            ),
            userData
        );
    }

    /// @dev Approves a subscription to an index in a super app callback. The subscriber's real time
    /// balance will not update until the subscription is approved, but once approved, the balance
    /// will be updated with prior distributions.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param ctx Context byte string used by the Superfluid host.
    /// @param token Super Token used with the index.
    /// @param publisher Publisher of the index.
    /// @param indexId ID of the index.
    function approveSubscriptionWithCtx(
        InitData storage idaLibrary,
        bytes memory ctx,
        ISuperfluidToken token,
        address publisher,
        uint32 indexId
    ) internal returns (bytes memory newCtx) {
        return approveSubscriptionWithCtx(
            idaLibrary,
            ctx,
            token,
            publisher,
            indexId,
            new bytes(0)
        );
    }

    /// @dev Approves a subscription to an index in a super app callback. The subscriber's real time
    /// balance will not update until the subscription is approved, but once approved, the balance
    /// will be updated with prior distributions. This takes arbitrary user data.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param ctx Context byte string used by the Superfluid host.
    /// @param token Super Token used with the index.
    /// @param publisher Publisher of the index.
    /// @param indexId ID of the index.
    /// @param userData Arbitrary user data field.
    function approveSubscriptionWithCtx(
        InitData storage idaLibrary,
        bytes memory ctx,
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        bytes memory userData
    ) internal returns (bytes memory newCtx) {
        (newCtx, ) = idaLibrary.host.callAgreementWithContext(
            idaLibrary.ida,
            abi.encodeCall(
                idaLibrary.ida.approveSubscription,
                (
                    token,
                    publisher,
                    indexId,
                    new bytes(0) // ctx placeholder
                )
            ),
            userData,
            ctx
        );
    }

    /// @dev Revokes a previously approved subscription.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param token Super Token used with the index.
    /// @param publisher Publisher of the index.
    /// @param indexId ID of the index.
    function revokeSubscription(
        InitData storage idaLibrary,
        ISuperfluidToken token,
        address publisher,
        uint32 indexId
    ) internal {
        revokeSubscription(idaLibrary, token, publisher, indexId, new bytes(0));
    }

    /// @dev Revokes a previously approved subscription. This takes arbitrary user data.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param token Super Token used with the index.
    /// @param publisher Publisher of the index.
    /// @param indexId ID of the index.
    /// @param userData Arbitrary user data field.
    function revokeSubscription(
        InitData storage idaLibrary,
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        bytes memory userData
    ) internal {
        idaLibrary.host.callAgreement(
            idaLibrary.ida,
            abi.encodeCall(
                idaLibrary.ida.revokeSubscription,
                (
                    token,
                    publisher,
                    indexId,
                    new bytes(0) // ctx placeholder
                )
            ),
            userData
        );
    }

    /// @dev Revokes a previously approved subscription in a super app callback.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param ctx Context byte string used by the Superfluid host.
    /// @param token Super Token used with the index.
    /// @param publisher Publisher of the index.
    /// @param indexId ID of the index.
    function revokeSubscriptionWithCtx(
        InitData storage idaLibrary,
        bytes memory ctx,
        ISuperfluidToken token,
        address publisher,
        uint32 indexId
    ) internal returns (bytes memory newCtx) {
        return revokeSubscriptionWithCtx(
            idaLibrary,
            ctx,
            token,
            publisher,
            indexId,
            new bytes(0)
        );
    }

    /// @dev Revokes a previously approved subscription in a super app callback. This takes
    /// arbitrary user data.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param ctx Context byte string used by the Superfluid host.
    /// @param token Super Token used with the index.
    /// @param publisher Publisher of the index.
    /// @param indexId ID of the index.
    /// @param userData Arbitrary user data field.
    function revokeSubscriptionWithCtx(
        InitData storage idaLibrary,
        bytes memory ctx,
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        bytes memory userData
    ) internal returns (bytes memory newCtx) {
        (newCtx, ) = idaLibrary.host.callAgreementWithContext(
            idaLibrary.ida,
            abi.encodeCall(
                idaLibrary.ida.revokeSubscription,
                (
                    token,
                    publisher,
                    indexId,
                    new bytes(0) // ctx placeholder
                )
            ),
            userData,
            ctx
        );
    }

    /// @dev Updates the units of a subscription. This changes the number of shares the subscriber
    /// holds.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param token Super Token used with the index.
    /// @param indexId ID of the index.
    /// @param subscriber Subscriber address whose units are to be updated.
    /// @param units New number of units the subscriber holds.
    function updateSubscriptionUnits(
        InitData storage idaLibrary,
        ISuperfluidToken token,
        uint32 indexId,
        address subscriber,
        uint128 units
    ) internal {
        updateSubscriptionUnits(idaLibrary, token, indexId, subscriber, units, new bytes(0));
    }

    /// @dev Updates the units of a subscription. This changes the number of shares the subscriber
    /// holds. This takes arbitrary user data.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param token Super Token used with the index.
    /// @param indexId ID of the index.
    /// @param subscriber Subscriber address whose units are to be updated.
    /// @param units New number of units the subscriber holds.
    /// @param userData Arbitrary user data field.
    function updateSubscriptionUnits(
        InitData storage idaLibrary,
        ISuperfluidToken token,
        uint32 indexId,
        address subscriber,
        uint128 units,
        bytes memory userData
    ) internal {
        idaLibrary.host.callAgreement(
            idaLibrary.ida,
            abi.encodeCall(
                idaLibrary.ida.updateSubscription,
                (
                    token,
                    indexId,
                    subscriber,
                    units,
                    new bytes(0) // ctx placeholder
                )
            ),
            userData
        );
    }

    /// @dev Updates the units of a subscription in a super app callback. This changes the number of
    /// shares the subscriber holds.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param ctx Context byte string used by the Superfluid host.
    /// @param token Super Token used with the index.
    /// @param indexId ID of the index.
    /// @param subscriber Subscriber address whose units are to be updated.
    /// @param units New number of units the subscriber holds.
    function updateSubscriptionUnitsWithCtx(
        InitData storage idaLibrary,
        bytes memory ctx,
        ISuperfluidToken token,
        uint32 indexId,
        address subscriber,
        uint128 units
    ) internal returns (bytes memory newCtx) {
        return updateSubscriptionUnitsWithCtx(
            idaLibrary,
            ctx,
            token,
            indexId,
            subscriber,
            units,
            new bytes(0)
        );
    }

    /// @dev Updates the units of a subscription in a super app callback. This changes the number of
    /// shares the subscriber holds. This takes arbitrary user data.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param ctx Context byte string used by the Superfluid host.
    /// @param token Super Token used with the index.
    /// @param indexId ID of the index.
    /// @param subscriber Subscriber address whose units are to be updated.
    /// @param units New number of units the subscriber holds.
    /// @param userData Arbitrary user data field.
    function updateSubscriptionUnitsWithCtx(
        InitData storage idaLibrary,
        bytes memory ctx,
        ISuperfluidToken token,
        uint32 indexId,
        address subscriber,
        uint128 units,
        bytes memory userData
    ) internal returns (bytes memory newCtx) {
        (newCtx, ) = idaLibrary.host.callAgreementWithContext(
            idaLibrary.ida,
            abi.encodeCall(
                idaLibrary.ida.updateSubscription,
                (
                    token,
                    indexId,
                    subscriber,
                    units,
                    new bytes(0) // ctx placeholder
                )
            ),
            userData,
            ctx
        );
    }

    /// @dev Deletes a subscription, setting a subcriber's units to zero.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param token Super Token used with the index.
    /// @param publisher Publisher of the index.
    /// @param indexId ID of the index.
    /// @param subscriber Subscriber address whose units are to be deleted.
    function deleteSubscription(
        InitData storage idaLibrary,
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        address subscriber
    ) internal {
        deleteSubscription(idaLibrary, token, publisher, indexId, subscriber, new bytes(0));
    }

    /// @dev Deletes a subscription, setting a subcriber's units to zero. This takes arbitrary user
    /// data.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param token Super Token used with the index.
    /// @param publisher Publisher of the index.
    /// @param indexId ID of the index.
    /// @param subscriber Subscriber address whose units are to be deleted.
    /// @param userData Arbitrary user data field.
    function deleteSubscription(
        InitData storage idaLibrary,
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        address subscriber,
        bytes memory userData
    ) internal {
        idaLibrary.host.callAgreement(
            idaLibrary.ida,
            abi.encodeCall(
                idaLibrary.ida.deleteSubscription,
                (
                    token,
                    publisher,
                    indexId,
                    subscriber,
                    new bytes(0) // ctx placeholder
                )
            ),
            userData
        );
    }

    /// @dev Deletes a subscription in a super app callback, setting a subcriber's units to zero.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param ctx Context byte string used by the Superfluid host.
    /// @param token Super Token used with the index.
    /// @param publisher Publisher of the index.
    /// @param indexId ID of the index.
    /// @param subscriber Subscriber address whose units are to be deleted.
    function deleteSubscriptionWithCtx(
        InitData storage idaLibrary,
        bytes memory ctx,
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        address subscriber
    ) internal returns (bytes memory newCtx) {
        return deleteSubscriptionWithCtx(
            idaLibrary,
            ctx,
            token,
            publisher,
            indexId,
            subscriber,
            new bytes(0)
        );
    }

    /// @dev Deletes a subscription in a super app callback, setting a subcriber's units to zero.
    /// This takes arbitrary user data.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param ctx Context byte string used by the Superfluid host.
    /// @param token Super Token used with the index.
    /// @param publisher Publisher of the index.
    /// @param indexId ID of the index.
    /// @param subscriber Subscriber address whose units are to be deleted.
    /// @param userData Arbitrary user data field.
    function deleteSubscriptionWithCtx(
        InitData storage idaLibrary,
        bytes memory ctx,
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        address subscriber,
        bytes memory userData
    ) internal returns (bytes memory newCtx) {
        (newCtx, ) = idaLibrary.host.callAgreementWithContext(
            idaLibrary.ida,
            abi.encodeCall(
                idaLibrary.ida.deleteSubscription,
                (
                    token,
                    publisher,
                    indexId,
                    subscriber,
                    new bytes(0) // ctx placeholder
                )
            ),
            userData,
            ctx
        );
    }

    /// @dev Claims pending distribution. Subscription should not be approved.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param token Super Token used with the index.
    /// @param publisher Publisher of the index.
    /// @param indexId ID of the index.
    /// @param subscriber Subscriber address that receives the claim.
    function claim(
        InitData storage idaLibrary,
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        address subscriber
    ) internal {
        claim(idaLibrary, token, publisher, indexId, subscriber, new bytes(0));
    }

    /// @dev Claims pending distribution. Subscription should not be approved. This takes arbitrary
    /// user data.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param token Super Token used with the index.
    /// @param publisher Publisher of the index.
    /// @param indexId ID of the index.
    /// @param subscriber Subscriber address that receives the claim.
    /// @param userData Arbitrary user data field.
    function claim(
        InitData storage idaLibrary,
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        address subscriber,
        bytes memory userData
    ) internal {
        idaLibrary.host.callAgreement(
            idaLibrary.ida,
            abi.encodeCall(
                idaLibrary.ida.claim,
                (
                    token,
                    publisher,
                    indexId,
                    subscriber,
                    new bytes(0) // ctx placeholder
                )
            ),
            userData
        );
    }

    /// @dev Claims pending distribution in a super app callback. Subscription should not be
    /// approved.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param token Super Token used with the index.
    /// @param publisher Publisher of the index.
    /// @param indexId ID of the index.
    /// @param subscriber Subscriber address that receives the claim.
    function claimWithCtx(
        InitData storage idaLibrary,
        bytes memory ctx,
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        address subscriber
    ) internal returns (bytes memory newCtx) {
        return claimWithCtx(
            idaLibrary,
            ctx,
            token,
            publisher,
            indexId,
            subscriber,
            new bytes(0)
        );
    }

    /// @dev Claims pending distribution in a super app callback. Subscription should not be
    /// approved. This takes arbitrary user data.
    /// @param idaLibrary Storage pointer to host and ida interfaces.
    /// @param token Super Token used with the index.
    /// @param publisher Publisher of the index.
    /// @param indexId ID of the index.
    /// @param subscriber Subscriber address that receives the claim.
    /// @param userData Arbitrary user data field.
    function claimWithCtx(
        InitData storage idaLibrary,
        bytes memory ctx,
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        address subscriber,
        bytes memory userData
    ) internal returns (bytes memory newCtx) {
        (newCtx, ) = idaLibrary.host.callAgreementWithContext(
            idaLibrary.ida,
            abi.encodeCall(
                idaLibrary.ida.claim,
                (
                    token,
                    publisher,
                    indexId,
                    subscriber,
                    new bytes(0) // ctx placeholder
                )
            ),
            userData,
            ctx
        );
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.4;

import { ISuperAgreement } from "../superfluid/ISuperAgreement.sol";
import { ISuperfluidToken } from "../superfluid/ISuperfluidToken.sol";
import { SuperfluidErrors } from "../superfluid/Definitions.sol";


/**
 * @title Instant Distribution Agreement interface
 * @author Superfluid
 *
 * @notice 
 *   - A publisher can create as many as indices as possibly identifiable with `indexId`.
 *     - `indexId` is deliberately limited to 32 bits, to avoid the chance for sha-3 collision.
 *       Despite knowing sha-3 collision is only theoretical.
 *   - A publisher can create a subscription to an index for any subscriber.
 *   - A subscription consists of:
 *     - The index it subscribes to.
 *     - Number of units subscribed.
 *   - An index consists of:
 *     - Current value as `uint128 indexValue`.
 *     - Total units of the approved subscriptions as `uint128 totalUnitsApproved`.
 *     - Total units of the non approved subscription as `uint128 totalUnitsPending`.
 *   - A publisher can update an index with a new value that doesn't decrease.
 *   - A publisher can update a subscription with any number of units.
 *   - A publisher or a subscriber can delete a subscription and reset its units to zero.
 *   - A subscriber must approve the index in order to receive distributions from the publisher
 *     each time the index is updated.
 *     - The amount distributed is $$\Delta{index} * units$$
 *   - Distributions to a non approved subscription stays in the publisher's deposit until:
 *     - the subscriber approves the subscription (side effect),
 *     - the publisher updates the subscription (side effect),
 *     - the subscriber deletes the subscription even if it is never approved (side effect),
 *     - or the subscriber can explicitly claim them.
 */
abstract contract IInstantDistributionAgreementV1 is ISuperAgreement {

    /**************************************************************************
     * Errors
     *************************************************************************/
    error IDA_INDEX_SHOULD_GROW();             // index value should grow
    error IDA_OPERATION_NOT_ALLOWED();         // operation not allowed

    /// @dev ISuperAgreement.agreementType implementation
    function agreementType() external override pure returns (bytes32) {
        return keccak256("org.superfluid-finance.agreements.InstantDistributionAgreement.v1");
    }

    /**************************************************************************
     * Index operations
     *************************************************************************/

    /**
     * @dev Create a new index for the publisher
     * @param token Super token address
     * @param indexId Id of the index
     * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
     *
     * @custom:callbacks 
     * None
     */
    function createIndex(
        ISuperfluidToken token,
        uint32 indexId,
        bytes calldata ctx)
            external
            virtual
            returns(bytes memory newCtx);
    /**
    * @dev Index created event
    * @param token Super token address
    * @param publisher Index creator and publisher
    * @param indexId The specified indexId of the newly created index
    * @param userData The user provided data
    */
    event IndexCreated(
        ISuperfluidToken indexed token,
        address indexed publisher,
        uint32 indexed indexId,
        bytes userData);

    /**
     * @dev Query the data of a index
     * @param token Super token address
     * @param publisher The publisher of the index
     * @param indexId Id of the index
     * @return exist Does the index exist
     * @return indexValue Value of the current index
     * @return totalUnitsApproved Total units approved for the index
     * @return totalUnitsPending Total units pending approval for the index
     */
    function getIndex(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId)
            external
            view
            virtual
            returns(
                bool exist,
                uint128 indexValue,
                uint128 totalUnitsApproved,
                uint128 totalUnitsPending);

    /**
     * @dev Calculate actual distribution amount
     * @param token Super token address
     * @param publisher The publisher of the index
     * @param indexId Id of the index
     * @param amount The amount of tokens desired to be distributed
     * @return actualAmount The amount to be distributed after ensuring no rounding errors
     * @return newIndexValue The index value given the desired amount of tokens to be distributed
     */
    function calculateDistribution(
       ISuperfluidToken token,
       address publisher,
       uint32 indexId,
       uint256 amount)
           external view
           virtual
           returns(
               uint256 actualAmount,
               uint128 newIndexValue);

    /**
     * @dev Update index value of an index
     * @param token Super token address
     * @param indexId Id of the index
     * @param indexValue Value of the index
     * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
     *
     * @custom:callbacks 
     * None
     */
    function updateIndex(
        ISuperfluidToken token,
        uint32 indexId,
        uint128 indexValue,
        bytes calldata ctx)
            external
            virtual
            returns(bytes memory newCtx);
    /**
      * @dev Index updated event
      * @param token Super token address
      * @param publisher Index updater and publisher
      * @param indexId The specified indexId of the updated index
      * @param oldIndexValue The previous index value
      * @param newIndexValue The updated index value
      * @param totalUnitsPending The total units pending when the indexValue was updated
      * @param totalUnitsApproved The total units approved when the indexValue was updated
      * @param userData The user provided data
      */
    event IndexUpdated(
        ISuperfluidToken indexed token,
        address indexed publisher,
        uint32 indexed indexId,
        uint128 oldIndexValue,
        uint128 newIndexValue,
        uint128 totalUnitsPending,
        uint128 totalUnitsApproved,
        bytes userData);

    /**
     * @dev Distribute tokens through the index
     * @param token Super token address
     * @param indexId Id of the index
     * @param amount The amount of tokens desired to be distributed
     * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
     *
     * @custom:note 
     * - This is a convenient version of updateIndex. It adds to the index
     *   a delta that equals to `amount / totalUnits`
     * - The actual amount distributed could be obtained via
     *   `calculateDistribution`. This is due to precision error with index
     *   value and units data range
     *
     * @custom:callbacks 
     * None
     */
    function distribute(
        ISuperfluidToken token,
        uint32 indexId,
        uint256 amount,
        bytes calldata ctx)
            external
            virtual
            returns(bytes memory newCtx);


    /**************************************************************************
     * Subscription operations
     *************************************************************************/

    /**
     * @dev Approve the subscription of an index
     * @param token Super token address
     * @param publisher The publisher of the index
     * @param indexId Id of the index
     * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
     *
     * @custom:callbacks 
     * - if subscription exist
     *   - AgreementCreated callback to the publisher:
     *      - agreementId is for the subscription
     * - if subscription does not exist
     *   - AgreementUpdated callback to the publisher:
     *      - agreementId is for the subscription
     */
    function approveSubscription(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        bytes calldata ctx)
            external
            virtual
            returns(bytes memory newCtx);
    /**
      * @dev Index subscribed event
      * @param token Super token address
      * @param publisher Index publisher
      * @param indexId The specified indexId
      * @param subscriber The approved subscriber
      * @param userData The user provided data
      */
    event IndexSubscribed(
        ISuperfluidToken indexed token,
        address indexed publisher,
        uint32 indexed indexId,
        address subscriber,
        bytes userData);

    /**
      * @dev Subscription approved event
      * @param token Super token address
      * @param subscriber The approved subscriber
      * @param publisher Index publisher
      * @param indexId The specified indexId
      * @param userData The user provided data
      */
    event SubscriptionApproved(
        ISuperfluidToken indexed token,
        address indexed subscriber,
        address publisher,
        uint32 indexId,
        bytes userData);

    /**
    * @notice Revoke the subscription of an index
    * @dev "Unapproves" the subscription and moves approved units to pending
    * @param token Super token address
    * @param publisher The publisher of the index
    * @param indexId Id of the index
    * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
    *
    * @custom:callbacks 
    * - AgreementUpdated callback to the publisher:
    *    - agreementId is for the subscription
    */
    function revokeSubscription(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        bytes calldata ctx)
         external
         virtual
         returns(bytes memory newCtx);
    /**
      * @dev Index unsubscribed event
      * @param token Super token address
      * @param publisher Index publisher
      * @param indexId The specified indexId
      * @param subscriber The unsubscribed subscriber
      * @param userData The user provided data
      */
    event IndexUnsubscribed(
        ISuperfluidToken indexed token,
        address indexed publisher,
        uint32 indexed indexId,
        address subscriber,
        bytes userData);
    
    /**
      * @dev Subscription approved event
      * @param token Super token address
      * @param subscriber The approved subscriber
      * @param publisher Index publisher
      * @param indexId The specified indexId
      * @param userData The user provided data
      */
    event SubscriptionRevoked(
        ISuperfluidToken indexed token,
        address indexed subscriber,
        address publisher,
        uint32 indexId,
        bytes userData);

    /**
     * @dev Update the nuber of units of a subscription
     * @param token Super token address
     * @param indexId Id of the index
     * @param subscriber The subscriber of the index
     * @param units Number of units of the subscription
     * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
     *
     * @custom:callbacks 
     * - if subscription exist
     *   - AgreementCreated callback to the subscriber:
     *      - agreementId is for the subscription
     * - if subscription does not exist
     *   - AgreementUpdated callback to the subscriber:
     *      - agreementId is for the subscription
     */
    function updateSubscription(
        ISuperfluidToken token,
        uint32 indexId,
        address subscriber,
        uint128 units,
        bytes calldata ctx)
            external
            virtual
            returns(bytes memory newCtx);

    /**
      * @dev Index units updated event
      * @param token Super token address
      * @param publisher Index publisher
      * @param indexId The specified indexId
      * @param subscriber The subscriber units updated
      * @param units The new units amount
      * @param userData The user provided data
      */
    event IndexUnitsUpdated(
        ISuperfluidToken indexed token,
        address indexed publisher,
        uint32 indexed indexId,
        address subscriber,
        uint128 units,
        bytes userData);
    
    /**
      * @dev Subscription units updated event
      * @param token Super token address
      * @param subscriber The subscriber units updated
      * @param indexId The specified indexId
      * @param publisher Index publisher
      * @param units The new units amount
      * @param userData The user provided data
      */
    event SubscriptionUnitsUpdated(
        ISuperfluidToken indexed token,
        address indexed subscriber,
        address publisher,
        uint32 indexId,
        uint128 units,
        bytes userData);

    /**
     * @dev Get data of a subscription
     * @param token Super token address
     * @param publisher The publisher of the index
     * @param indexId Id of the index
     * @param subscriber The subscriber of the index
     * @return exist Does the subscription exist?
     * @return approved Is the subscription approved?
     * @return units Units of the suscription
     * @return pendingDistribution Pending amount of tokens to be distributed for unapproved subscription
     */
    function getSubscription(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        address subscriber)
            external
            view
            virtual
            returns(
                bool exist,
                bool approved,
                uint128 units,
                uint256 pendingDistribution
            );

    /**
     * @notice Get data of a subscription by agreement ID
     * @dev indexId (agreementId) is the keccak256 hash of encodePacked("publisher", publisher, indexId)
     * @param token Super token address
     * @param agreementId The agreement ID
     * @return publisher The publisher of the index
     * @return indexId Id of the index
     * @return approved Is the subscription approved?
     * @return units Units of the suscription
     * @return pendingDistribution Pending amount of tokens to be distributed for unapproved subscription
     */
    function getSubscriptionByID(
        ISuperfluidToken token,
        bytes32 agreementId)
            external
            view
            virtual
            returns(
                address publisher,
                uint32 indexId,
                bool approved,
                uint128 units,
                uint256 pendingDistribution
            );

    /**
     * @dev List subscriptions of an user
     * @param token Super token address
     * @param subscriber The subscriber's address
     * @return publishers Publishers of the subcriptions
     * @return indexIds Indexes of the subscriptions
     * @return unitsList Units of the subscriptions
     */
    function listSubscriptions(
        ISuperfluidToken token,
        address subscriber)
            external
            view
            virtual
            returns(
                address[] memory publishers,
                uint32[] memory indexIds,
                uint128[] memory unitsList);

    /**
     * @dev Delete the subscription of an user
     * @param token Super token address
     * @param publisher The publisher of the index
     * @param indexId Id of the index
     * @param subscriber The subscriber's address
     * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
     *
     * @custom:callbacks 
     * - if the subscriber called it
     *   - AgreementTerminated callback to the publsiher:
     *      - agreementId is for the subscription
     * - if the publisher called it
     *   - AgreementTerminated callback to the subscriber:
     *      - agreementId is for the subscription
     */
    function deleteSubscription(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        address subscriber,
        bytes calldata ctx)
            external
            virtual
            returns(bytes memory newCtx);

    /**
    * @dev Claim pending distributions
    * @param token Super token address
    * @param publisher The publisher of the index
    * @param indexId Id of the index
    * @param subscriber The subscriber's address
    * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
    *
    * @custom:note The subscription should not be approved yet
    *
    * @custom:callbacks 
    * - AgreementUpdated callback to the publisher:
    *    - agreementId is for the subscription
    */
    function claim(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        address subscriber,
        bytes calldata ctx)
        external
        virtual
        returns(bytes memory newCtx);
    
    /**
      * @dev Index distribution claimed event
      * @param token Super token address
      * @param publisher Index publisher
      * @param indexId The specified indexId
      * @param subscriber The subscriber units updated
      * @param amount The pending amount claimed
      */
    event IndexDistributionClaimed(
        ISuperfluidToken indexed token,
        address indexed publisher,
        uint32 indexed indexId,
        address subscriber,
        uint256 amount);
    
    /**
      * @dev Subscription distribution claimed event
      * @param token Super token address
      * @param subscriber The subscriber units updated
      * @param publisher Index publisher
      * @param indexId The specified indexId
      * @param amount The pending amount claimed
      */
    event SubscriptionDistributionClaimed(
        ISuperfluidToken indexed token,
        address indexed subscriber,
        address publisher,
        uint32 indexId,
        uint256 amount);

}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.4;

import { ISuperToken } from "../superfluid/ISuperToken.sol";


/**
 * @title Super ETH (SETH) custom token interface
 * @author Superfluid
 */
interface ISETHCustom {
    // using native token
    function upgradeByETH() external payable;
    function upgradeByETHTo(address to) external payable;
    function downgradeToETH(uint wad) external;
}

/**
 * @title Super ETH (SETH) full interface
 * @author Superfluid
 */
// solhint-disable-next-line no-empty-blocks
interface ISETH is ISETHCustom, ISuperToken {}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.4;

import { ISuperfluidGovernance } from "./ISuperfluidGovernance.sol";
import { ISuperfluidToken } from "./ISuperfluidToken.sol";
import { ISuperToken } from "./ISuperToken.sol";
import { ISuperTokenFactory } from "./ISuperTokenFactory.sol";
import { ISuperAgreement } from "./ISuperAgreement.sol";
import { ISuperApp } from "./ISuperApp.sol";
import {
    BatchOperation,
    ContextDefinitions,
    FlowOperatorDefinitions,
    SuperAppDefinitions,
    SuperfluidErrors,
    SuperfluidGovernanceConfigs
} from "./Definitions.sol";
import { TokenInfo } from "../tokens/TokenInfo.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC777 } from "@openzeppelin/contracts/token/ERC777/IERC777.sol";

/**
 * @title Host interface
 * @author Superfluid
 * @notice This is the central contract of the system where super agreement, super app
 * and super token features are connected.
 *
 * The Superfluid host contract is also the entry point for the protocol users,
 * where batch call and meta transaction are provided for UX improvements.
 *
 */
interface ISuperfluid {

    /**************************************************************************
     * Errors
     *************************************************************************/
    // Superfluid Custom Errors
    error HOST_AGREEMENT_CALLBACK_IS_NOT_ACTION();
    error HOST_CANNOT_DOWNGRADE_TO_NON_UPGRADEABLE();
    error HOST_CALL_AGREEMENT_WITH_CTX_FROM_WRONG_ADDRESS();
    error HOST_CALL_APP_ACTION_WITH_CTX_FROM_WRONG_ADDRESS();
    error HOST_INVALID_CONFIG_WORD();
    error HOST_MAX_256_AGREEMENTS();
    error HOST_NON_UPGRADEABLE();
    error HOST_NON_ZERO_LENGTH_PLACEHOLDER_CTX();
    error HOST_ONLY_GOVERNANCE();
    error HOST_UNKNOWN_BATCH_CALL_OPERATION_TYPE();

    // App Related Custom Errors
    error HOST_INVALID_OR_EXPIRED_SUPER_APP_REGISTRATION_KEY();
    error HOST_NOT_A_SUPER_APP();
    error HOST_NO_APP_REGISTRATION_PERMISSIONS();
    error HOST_RECEIVER_IS_NOT_SUPER_APP();
    error HOST_SENDER_IS_NOT_SUPER_APP();
    error HOST_SOURCE_APP_NEEDS_HIGHER_APP_LEVEL();
    error HOST_SUPER_APP_IS_JAILED();
    error HOST_SUPER_APP_ALREADY_REGISTERED();
    error HOST_UNAUTHORIZED_SUPER_APP_FACTORY();

    /**************************************************************************
     * Time
     *
     * > The Oracle: You have the sight now, Neo. You are looking at the world without time.
     * > Neo: Then why can't I see what happens to her?
     * > The Oracle: We can never see past the choices we don't understand.
     * >       - The Oracle and Neo conversing about the future of Trinity and the effects of Neo's choices
     *************************************************************************/

    function getNow() external view returns (uint256);

    /**************************************************************************
     * Governance
     *************************************************************************/

    /**
     * @dev Get the current governance address of the Superfluid host
     */
    function getGovernance() external view returns(ISuperfluidGovernance governance);

    /**
     * @dev Replace the current governance with a new one
     */
    function replaceGovernance(ISuperfluidGovernance newGov) external;
    /**
     * @dev Governance replaced event
     * @param oldGov Address of the old governance contract
     * @param newGov Address of the new governance contract
     */
    event GovernanceReplaced(ISuperfluidGovernance oldGov, ISuperfluidGovernance newGov);

    /**************************************************************************
     * Agreement Whitelisting
     *************************************************************************/

    /**
     * @dev Register a new agreement class to the system
     * @param agreementClassLogic Initial agreement class code
     *
     * @custom:modifiers 
     * - onlyGovernance
     */
    function registerAgreementClass(ISuperAgreement agreementClassLogic) external;
    /**
     * @notice Agreement class registered event
     * @dev agreementType is the keccak256 hash of: "org.superfluid-finance.agreements.<AGREEMENT_NAME>.<VERSION>"
     * @param agreementType The agreement type registered
     * @param code Address of the new agreement
     */
    event AgreementClassRegistered(bytes32 agreementType, address code);

    /**
    * @dev Update code of an agreement class
    * @param agreementClassLogic New code for the agreement class
    *
    * @custom:modifiers 
    *  - onlyGovernance
    */
    function updateAgreementClass(ISuperAgreement agreementClassLogic) external;
    /**
     * @notice Agreement class updated event
     * @dev agreementType is the keccak256 hash of: "org.superfluid-finance.agreements.<AGREEMENT_NAME>.<VERSION>"
     * @param agreementType The agreement type updated
     * @param code Address of the new agreement
     */
    event AgreementClassUpdated(bytes32 agreementType, address code);

    /**
    * @notice Check if the agreement type is whitelisted
    * @dev agreementType is the keccak256 hash of: "org.superfluid-finance.agreements.<AGREEMENT_NAME>.<VERSION>"
    */
    function isAgreementTypeListed(bytes32 agreementType) external view returns(bool yes);

    /**
    * @dev Check if the agreement class is whitelisted
    */
    function isAgreementClassListed(ISuperAgreement agreementClass) external view returns(bool yes);

    /**
    * @notice Get agreement class
    * @dev agreementType is the keccak256 hash of: "org.superfluid-finance.agreements.<AGREEMENT_NAME>.<VERSION>"
    */
    function getAgreementClass(bytes32 agreementType) external view returns(ISuperAgreement agreementClass);

    /**
    * @dev Map list of the agreement classes using a bitmap
    * @param bitmap Agreement class bitmap
    */
    function mapAgreementClasses(uint256 bitmap)
        external view
        returns (ISuperAgreement[] memory agreementClasses);

    /**
    * @notice Create a new bitmask by adding a agreement class to it
    * @dev agreementType is the keccak256 hash of: "org.superfluid-finance.agreements.<AGREEMENT_NAME>.<VERSION>"
    * @param bitmap Agreement class bitmap
    */
    function addToAgreementClassesBitmap(uint256 bitmap, bytes32 agreementType)
        external view
        returns (uint256 newBitmap);

    /**
    * @notice Create a new bitmask by removing a agreement class from it
    * @dev agreementType is the keccak256 hash of: "org.superfluid-finance.agreements.<AGREEMENT_NAME>.<VERSION>"
    * @param bitmap Agreement class bitmap
    */
    function removeFromAgreementClassesBitmap(uint256 bitmap, bytes32 agreementType)
        external view
        returns (uint256 newBitmap);

    /**************************************************************************
    * Super Token Factory
    **************************************************************************/

    /**
     * @dev Get the super token factory
     * @return factory The factory
     */
    function getSuperTokenFactory() external view returns (ISuperTokenFactory factory);

    /**
     * @dev Get the super token factory logic (applicable to upgradable deployment)
     * @return logic The factory logic
     */
    function getSuperTokenFactoryLogic() external view returns (address logic);

    /**
     * @dev Update super token factory
     * @param newFactory New factory logic
     */
    function updateSuperTokenFactory(ISuperTokenFactory newFactory) external;
    /**
     * @dev SuperToken factory updated event
     * @param newFactory Address of the new factory
     */
    event SuperTokenFactoryUpdated(ISuperTokenFactory newFactory);

    /**
     * @notice Update the super token logic to the latest
     * @dev Refer to ISuperTokenFactory.Upgradability for expected behaviours
     */
    function updateSuperTokenLogic(ISuperToken token) external;
    /**
     * @dev SuperToken logic updated event
     * @param code Address of the new SuperToken logic
     */
    event SuperTokenLogicUpdated(ISuperToken indexed token, address code);

    /**************************************************************************
     * App Registry
     *************************************************************************/

    /**
     * @dev Message sender (must be a contract) declares itself as a super app.
     * @custom:deprecated you should use `registerAppWithKey` or `registerAppByFactory` instead,
     * because app registration is currently governance permissioned on mainnets.
     * @param configWord The super app manifest configuration, flags are defined in
     * `SuperAppDefinitions`
     */
    function registerApp(uint256 configWord) external;
    /**
     * @dev App registered event
     * @param app Address of jailed app
     */
    event AppRegistered(ISuperApp indexed app);

    /**
     * @dev Message sender declares itself as a super app.
     * @param configWord The super app manifest configuration, flags are defined in `SuperAppDefinitions`
     * @param registrationKey The registration key issued by the governance, needed to register on a mainnet.
     * @notice See https://github.com/superfluid-finance/protocol-monorepo/wiki/Super-App-White-listing-Guide
     * On testnets or in dev environment, a placeholder (e.g. empty string) can be used.
     * While the message sender must be the super app itself, the transaction sender (tx.origin)
     * must be the deployer account the registration key was issued for.
     */
    function registerAppWithKey(uint256 configWord, string calldata registrationKey) external;

    /**
     * @dev Message sender (must be a contract) declares app as a super app
     * @param configWord The super app manifest configuration, flags are defined in `SuperAppDefinitions`
     * @notice On mainnet deployments, only factory contracts pre-authorized by governance can use this.
     * See https://github.com/superfluid-finance/protocol-monorepo/wiki/Super-App-White-listing-Guide
     */
    function registerAppByFactory(ISuperApp app, uint256 configWord) external;

    /**
     * @dev Query if the app is registered
     * @param app Super app address
     */
    function isApp(ISuperApp app) external view returns(bool);

    /**
     * @dev Query app callbacklevel
     * @param app Super app address
     */
    function getAppCallbackLevel(ISuperApp app) external view returns(uint8 appCallbackLevel);

    /**
     * @dev Get the manifest of the super app
     * @param app Super app address
     */
    function getAppManifest(
        ISuperApp app
    )
        external view
        returns (
            bool isSuperApp,
            bool isJailed,
            uint256 noopMask
        );

    /**
     * @dev Query if the app has been jailed
     * @param app Super app address
     */
    function isAppJailed(ISuperApp app) external view returns (bool isJail);

    /**
     * @dev Whitelist the target app for app composition for the source app (msg.sender)
     * @param targetApp The target super app address
     */
    function allowCompositeApp(ISuperApp targetApp) external;

    /**
     * @dev Query if source app is allowed to call the target app as downstream app
     * @param app Super app address
     * @param targetApp The target super app address
     */
    function isCompositeAppAllowed(
        ISuperApp app,
        ISuperApp targetApp
    )
        external view
        returns (bool isAppAllowed);

    /**************************************************************************
     * Agreement Framework
     *
     * Agreements use these function to trigger super app callbacks, updates
     * app credit and charge gas fees.
     *
     * These functions can only be called by registered agreements.
     *************************************************************************/

    /**
     * @dev (For agreements) StaticCall the app before callback
     * @param  app               The super app.
     * @param  callData          The call data sending to the super app.
     * @param  isTermination     Is it a termination callback?
     * @param  ctx               Current ctx, it will be validated.
     * @return cbdata            Data returned from the callback.
     */
    function callAppBeforeCallback(
        ISuperApp app,
        bytes calldata callData,
        bool isTermination,
        bytes calldata ctx
    )
        external
        // onlyAgreement
        // assertValidCtx(ctx)
        returns(bytes memory cbdata);

    /**
     * @dev (For agreements) Call the app after callback
     * @param  app               The super app.
     * @param  callData          The call data sending to the super app.
     * @param  isTermination     Is it a termination callback?
     * @param  ctx               Current ctx, it will be validated.
     * @return newCtx            The current context of the transaction.
     */
    function callAppAfterCallback(
        ISuperApp app,
        bytes calldata callData,
        bool isTermination,
        bytes calldata ctx
    )
        external
        // onlyAgreement
        // assertValidCtx(ctx)
        returns(bytes memory newCtx);

    /**
     * @dev (For agreements) Create a new callback stack
     * @param  ctx                     The current ctx, it will be validated.
     * @param  app                     The super app.
     * @param  appCreditGranted        App credit granted so far.
     * @param  appCreditUsed           App credit used so far.
     * @return newCtx                  The current context of the transaction.
     */
    function appCallbackPush(
        bytes calldata ctx,
        ISuperApp app,
        uint256 appCreditGranted,
        int256 appCreditUsed,
        ISuperfluidToken appCreditToken
    )
        external
        // onlyAgreement
        // assertValidCtx(ctx)
        returns (bytes memory newCtx);

    /**
     * @dev (For agreements) Pop from the current app callback stack
     * @param  ctx                     The ctx that was pushed before the callback stack.
     * @param  appCreditUsedDelta      App credit used by the app.
     * @return newCtx                  The current context of the transaction.
     *
     * @custom:security
     * - Here we cannot do assertValidCtx(ctx), since we do not really save the stack in memory.
     * - Hence there is still implicit trust that the agreement handles the callback push/pop pair correctly.
     */
    function appCallbackPop(
        bytes calldata ctx,
        int256 appCreditUsedDelta
    )
        external
        // onlyAgreement
        returns (bytes memory newCtx);

    /**
     * @dev (For agreements) Use app credit.
     * @param  ctx                      The current ctx, it will be validated.
     * @param  appCreditUsedMore        See app credit for more details.
     * @return newCtx                   The current context of the transaction.
     */
    function ctxUseCredit(
        bytes calldata ctx,
        int256 appCreditUsedMore
    )
        external
        // onlyAgreement
        // assertValidCtx(ctx)
        returns (bytes memory newCtx);

    /**
     * @dev (For agreements) Jail the app.
     * @param  app                     The super app.
     * @param  reason                  Jail reason code.
     * @return newCtx                  The current context of the transaction.
     */
    function jailApp(
        bytes calldata ctx,
        ISuperApp app,
        uint256 reason
    )
        external
        // onlyAgreement
        // assertValidCtx(ctx)
        returns (bytes memory newCtx);

    /**
     * @dev Jail event for the app
     * @param app Address of jailed app
     * @param reason Reason the app is jailed (see Definitions.sol for the full list)
     */
    event Jail(ISuperApp indexed app, uint256 reason);

    /**************************************************************************
     * Contextless Call Proxies
     *
     * NOTE: For EOAs or non-app contracts, they are the entry points for interacting
     * with agreements or apps.
     *
     * NOTE: The contextual call data should be generated using
     * abi.encodeWithSelector. The context parameter should be set to "0x",
     * an empty bytes array as a placeholder to be replaced by the host
     * contract.
     *************************************************************************/

     /**
      * @dev Call agreement function
      * @param agreementClass The agreement address you are calling
      * @param callData The contextual call data with placeholder ctx
      * @param userData Extra user data being sent to the super app callbacks
      */
     function callAgreement(
         ISuperAgreement agreementClass,
         bytes calldata callData,
         bytes calldata userData
     )
        external
        //cleanCtx
        //isAgreement(agreementClass)
        returns(bytes memory returnedData);

    /**
     * @notice Call app action
     * @dev Main use case is calling app action in a batch call via the host
     * @param callData The contextual call data
     *
     * @custom:note See "Contextless Call Proxies" above for more about contextual call data.
     */
    function callAppAction(
        ISuperApp app,
        bytes calldata callData
    )
        external
        //cleanCtx
        //isAppActive(app)
        //isValidAppAction(callData)
        returns(bytes memory returnedData);

    /**************************************************************************
     * Contextual Call Proxies and Context Utilities
     *
     * For apps, they must use context they receive to interact with
     * agreements or apps.
     *
     * The context changes must be saved and returned by the apps in their
     * callbacks always, any modification to the context will be detected and
     * the violating app will be jailed.
     *************************************************************************/

    /**
     * @dev Context Struct
     *
     * @custom:note on backward compatibility:
     * - Non-dynamic fields are padded to 32bytes and packed
     * - Dynamic fields are referenced through a 32bytes offset to their "parents" field (or root)
     * - The order of the fields hence should not be rearranged in order to be backward compatible:
     *    - non-dynamic fields will be parsed at the same memory location,
     *    - and dynamic fields will simply have a greater offset than it was.
     * - We cannot change the structure of the Context struct because of ABI compatibility requirements
     */
    struct Context {
        //
        // Call context
        //
        // app callback level
        uint8 appCallbackLevel;
        // type of call
        uint8 callType;
        // the system timestamp
        uint256 timestamp;
        // The intended message sender for the call
        address msgSender;

        //
        // Callback context
        //
        // For callbacks it is used to know which agreement function selector is called
        bytes4 agreementSelector;
        // User provided data for app callbacks
        bytes userData;

        //
        // App context
        //
        // app credit granted
        uint256 appCreditGranted;
        // app credit wanted by the app callback
        uint256 appCreditWantedDeprecated;
        // app credit used, allowing negative values over a callback session
        // the appCreditUsed value over a callback sessions is calculated with:
        // existing flow data owed deposit + sum of the callback agreements
        // deposit deltas 
        // the final value used to modify the state is determined by the
        // _adjustNewAppCreditUsed function (in AgreementLibrary.sol) which takes 
        // the appCreditUsed value reached in the callback session and the app
        // credit granted
        int256 appCreditUsed;
        // app address
        address appAddress;
        // app credit in super token
        ISuperfluidToken appCreditToken;
    }

    function callAgreementWithContext(
        ISuperAgreement agreementClass,
        bytes calldata callData,
        bytes calldata userData,
        bytes calldata ctx
    )
        external
        // requireValidCtx(ctx)
        // onlyAgreement(agreementClass)
        returns (bytes memory newCtx, bytes memory returnedData);

    function callAppActionWithContext(
        ISuperApp app,
        bytes calldata callData,
        bytes calldata ctx
    )
        external
        // requireValidCtx(ctx)
        // isAppActive(app)
        returns (bytes memory newCtx);

    function decodeCtx(bytes memory ctx)
        external pure
        returns (Context memory context);

    function isCtxValid(bytes calldata ctx) external view returns (bool);

    /**************************************************************************
    * Batch call
    **************************************************************************/
    /**
     * @dev Batch operation data
     */
    struct Operation {
        // Operation type. Defined in BatchOperation (Definitions.sol)
        uint32 operationType;
        // Operation target
        address target;
        // Data specific to the operation
        bytes data;
    }

    /**
     * @dev Batch call function
     * @param operations Array of batch operations
     */
    function batchCall(Operation[] calldata operations) external;

    /**
     * @dev Batch call function for trusted forwarders (EIP-2771)
     * @param operations Array of batch operations
     */
    function forwardBatchCall(Operation[] calldata operations) external;

    /**************************************************************************
     * Function modifiers for access control and parameter validations
     *
     * While they cannot be explicitly stated in function definitions, they are
     * listed in function definition comments instead for clarity.
     *
     * TODO: turning these off because solidity-coverage doesn't like it
     *************************************************************************/

     /* /// @dev The current superfluid context is clean.
     modifier cleanCtx() virtual;

     /// @dev Require the ctx being valid.
     modifier requireValidCtx(bytes memory ctx) virtual;

     /// @dev Assert the ctx being valid.
     modifier assertValidCtx(bytes memory ctx) virtual;

     /// @dev The agreement is a listed agreement.
     modifier isAgreement(ISuperAgreement agreementClass) virtual;

     // onlyGovernance

     /// @dev The msg.sender must be a listed agreement.
     modifier onlyAgreement() virtual;

     /// @dev The app is registered and not jailed.
     modifier isAppActive(ISuperApp app) virtual; */
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC777/IERC777.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Emitted when `amount` tokens are created by `operator` and assigned to `to`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` destroys `amount` tokens from `account`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` is made operator for `tokenHolder`
     */
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Emitted when `operator` is revoked its operator status for `tokenHolder`
     */
    event RevokedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.4;

import { ISuperAgreement } from "./ISuperAgreement.sol";
import { ISuperToken } from "./ISuperToken.sol";
import { ISuperfluidToken  } from "./ISuperfluidToken.sol";
import { ISuperfluid } from "./ISuperfluid.sol";
import { SuperfluidErrors } from "./Definitions.sol";


/**
 * @title Superfluid governance interface
 * @author Superfluid
 */
interface ISuperfluidGovernance {
    
    /**************************************************************************
     * Errors
     *************************************************************************/
    error SF_GOV_ARRAYS_NOT_SAME_LENGTH();
    error SF_GOV_INVALID_LIQUIDATION_OR_PATRICIAN_PERIOD();

    /**
     * @dev Replace the current governance with a new governance
     */
    function replaceGovernance(
        ISuperfluid host,
        address newGov) external;

    /**
     * @dev Register a new agreement class
     */
    function registerAgreementClass(
        ISuperfluid host,
        address agreementClass) external;

    /**
     * @dev Update logics of the contracts
     *
     * @custom:note 
     * - Because they might have inter-dependencies, it is good to have one single function to update them all
     */
    function updateContracts(
        ISuperfluid host,
        address hostNewLogic,
        address[] calldata agreementClassNewLogics,
        address superTokenFactoryNewLogic
    ) external;

    /**
     * @dev Update supertoken logic contract to the latest that is managed by the super token factory
     */
    function batchUpdateSuperTokenLogic(
        ISuperfluid host,
        ISuperToken[] calldata tokens) external;
    
    /**
     * @dev Set configuration as address value
     */
    function setConfig(
        ISuperfluid host,
        ISuperfluidToken superToken,
        bytes32 key,
        address value
    ) external;
    
    /**
     * @dev Set configuration as uint256 value
     */
    function setConfig(
        ISuperfluid host,
        ISuperfluidToken superToken,
        bytes32 key,
        uint256 value
    ) external;

    /**
     * @dev Clear configuration
     */
    function clearConfig(
        ISuperfluid host,
        ISuperfluidToken superToken,
        bytes32 key
    ) external;

    /**
     * @dev Get configuration as address value
     */
    function getConfigAsAddress(
        ISuperfluid host,
        ISuperfluidToken superToken,
        bytes32 key) external view returns (address value);

    /**
     * @dev Get configuration as uint256 value
     */
    function getConfigAsUint256(
        ISuperfluid host,
        ISuperfluidToken superToken,
        bytes32 key) external view returns (uint256 value);

}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.4;

import { ISuperAgreement } from "./ISuperAgreement.sol";
import { SuperfluidErrors } from "./Definitions.sol";

/**
 * @title Superfluid token interface
 * @author Superfluid
 */
interface ISuperfluidToken {
    /**************************************************************************
     * Basic information
     *************************************************************************/

    /**
     * @dev Get superfluid host contract address
     */
    function getHost() external view returns(address host);

    /**
     * @dev Encoded liquidation type data mainly used for handling stack to deep errors
     *
     * @custom:note 
     * - version: 1
     * - liquidationType key:
     *    - 0 = reward account receives reward (PIC period)
     *    - 1 = liquidator account receives reward (Pleb period)
     *    - 2 = liquidator account receives reward (Pirate period/bailout)
     */
    struct LiquidationTypeData {
        uint256 version;
        uint8 liquidationType;
    }

    /**************************************************************************
     * Real-time balance functions
     *************************************************************************/

    /**
    * @dev Calculate the real balance of a user, taking in consideration all agreements of the account
    * @param account for the query
    * @param timestamp Time of balance
    * @return availableBalance Real-time balance
    * @return deposit Account deposit
    * @return owedDeposit Account owed Deposit
    */
    function realtimeBalanceOf(
       address account,
       uint256 timestamp
    )
        external view
        returns (
            int256 availableBalance,
            uint256 deposit,
            uint256 owedDeposit);

    /**
     * @notice Calculate the realtime balance given the current host.getNow() value
     * @dev realtimeBalanceOf with timestamp equals to block timestamp
     * @param account for the query
     * @return availableBalance Real-time balance
     * @return deposit Account deposit
     * @return owedDeposit Account owed Deposit
     */
    function realtimeBalanceOfNow(
       address account
    )
        external view
        returns (
            int256 availableBalance,
            uint256 deposit,
            uint256 owedDeposit,
            uint256 timestamp);

    /**
    * @notice Check if account is critical
    * @dev A critical account is when availableBalance < 0
    * @param account The account to check
    * @param timestamp The time we'd like to check if the account is critical (should use future)
    * @return isCritical Whether the account is critical
    */
    function isAccountCritical(
        address account,
        uint256 timestamp
    )
        external view
        returns(bool isCritical);

    /**
    * @notice Check if account is critical now (current host.getNow())
    * @dev A critical account is when availableBalance < 0
    * @param account The account to check
    * @return isCritical Whether the account is critical
    */
    function isAccountCriticalNow(
        address account
    )
        external view
        returns(bool isCritical);

    /**
     * @notice Check if account is solvent
     * @dev An account is insolvent when the sum of deposits for a token can't cover the negative availableBalance
     * @param account The account to check
     * @param timestamp The time we'd like to check if the account is solvent (should use future)
     * @return isSolvent True if the account is solvent, false otherwise
     */
    function isAccountSolvent(
        address account,
        uint256 timestamp
    )
        external view
        returns(bool isSolvent);

    /**
     * @notice Check if account is solvent now
     * @dev An account is insolvent when the sum of deposits for a token can't cover the negative availableBalance
     * @param account The account to check
     * @return isSolvent True if the account is solvent, false otherwise
     */
    function isAccountSolventNow(
        address account
    )
        external view
        returns(bool isSolvent);

    /**
    * @notice Get a list of agreements that is active for the account
    * @dev An active agreement is one that has state for the account
    * @param account Account to query
    * @return activeAgreements List of accounts that have non-zero states for the account
    */
    function getAccountActiveAgreements(address account)
       external view
       returns(ISuperAgreement[] memory activeAgreements);


   /**************************************************************************
    * Super Agreement hosting functions
    *************************************************************************/

    /**
     * @dev Create a new agreement
     * @param id Agreement ID
     * @param data Agreement data
     */
    function createAgreement(
        bytes32 id,
        bytes32[] calldata data
    )
        external;
    /**
     * @dev Agreement created event
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @param data Agreement data
     */
    event AgreementCreated(
        address indexed agreementClass,
        bytes32 id,
        bytes32[] data
    );

    /**
     * @dev Get data of the agreement
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @return data Data of the agreement
     */
    function getAgreementData(
        address agreementClass,
        bytes32 id,
        uint dataLength
    )
        external view
        returns(bytes32[] memory data);

    /**
     * @dev Create a new agreement
     * @param id Agreement ID
     * @param data Agreement data
     */
    function updateAgreementData(
        bytes32 id,
        bytes32[] calldata data
    )
        external;
    /**
     * @dev Agreement updated event
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @param data Agreement data
     */
    event AgreementUpdated(
        address indexed agreementClass,
        bytes32 id,
        bytes32[] data
    );

    /**
     * @dev Close the agreement
     * @param id Agreement ID
     */
    function terminateAgreement(
        bytes32 id,
        uint dataLength
    )
        external;
    /**
     * @dev Agreement terminated event
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     */
    event AgreementTerminated(
        address indexed agreementClass,
        bytes32 id
    );

    /**
     * @dev Update agreement state slot
     * @param account Account to be updated
     *
     * @custom:note 
     * - To clear the storage out, provide zero-ed array of intended length
     */
    function updateAgreementStateSlot(
        address account,
        uint256 slotId,
        bytes32[] calldata slotData
    )
        external;
    /**
     * @dev Agreement account state updated event
     * @param agreementClass Contract address of the agreement
     * @param account Account updated
     * @param slotId slot id of the agreement state
     */
    event AgreementStateUpdated(
        address indexed agreementClass,
        address indexed account,
        uint256 slotId
    );

    /**
     * @dev Get data of the slot of the state of an agreement
     * @param agreementClass Contract address of the agreement
     * @param account Account to query
     * @param slotId slot id of the state
     * @param dataLength length of the state data
     */
    function getAgreementStateSlot(
        address agreementClass,
        address account,
        uint256 slotId,
        uint dataLength
    )
        external view
        returns (bytes32[] memory slotData);

    /**
     * @notice Settle balance from an account by the agreement
     * @dev The agreement needs to make sure that the balance delta is balanced afterwards
     * @param account Account to query.
     * @param delta Amount of balance delta to be settled
     *
     * @custom:modifiers 
     *  - onlyAgreement
     */
    function settleBalance(
        address account,
        int256 delta
    )
        external;

    /**
     * @dev Make liquidation payouts (v2)
     * @param id Agreement ID
     * @param liquidationTypeData Data regarding the version of the liquidation schema and the type
     * @param liquidatorAccount Address of the executor of the liquidation
     * @param useDefaultRewardAccount Whether or not the default reward account receives the rewardAmount
     * @param targetAccount Account to be liquidated
     * @param rewardAmount The amount the rewarded account will receive
     * @param targetAccountBalanceDelta The delta amount the target account balance should change by
     *
     * @custom:note 
     * - If a bailout is required (bailoutAmount > 0)
     *   - the actual reward (single deposit) goes to the executor,
     *   - while the reward account becomes the bailout account
     *   - total bailout include: bailout amount + reward amount
     *   - the targetAccount will be bailed out
     * - If a bailout is not required
     *   - the targetAccount will pay the rewardAmount
     *   - the liquidator (reward account in PIC period) will receive the rewardAmount
     *
     * @custom:modifiers 
     *  - onlyAgreement
     */
    function makeLiquidationPayoutsV2
    (
        bytes32 id,
        bytes memory liquidationTypeData,
        address liquidatorAccount,
        bool useDefaultRewardAccount,
        address targetAccount,
        uint256 rewardAmount,
        int256 targetAccountBalanceDelta
    ) external;
    /**
     * @dev Agreement liquidation event v2 (including agent account)
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @param liquidatorAccount Address of the executor of the liquidation
     * @param targetAccount Account of the stream sender
     * @param rewardAmountReceiver Account that collects the reward or bails out insolvent accounts
     * @param rewardAmount The amount the reward recipient account balance should change by
     * @param targetAccountBalanceDelta The amount the sender account balance should change by
     * @param liquidationTypeData The encoded liquidation type data including the version (how to decode)
     *
     * @custom:note 
     * Reward account rule:
     * - if the agreement is liquidated during the PIC period
     *   - the rewardAmountReceiver will get the rewardAmount (remaining deposit), regardless of the liquidatorAccount
     *   - the targetAccount will pay for the rewardAmount
     * - if the agreement is liquidated after the PIC period AND the targetAccount is solvent
     *   - the rewardAmountReceiver will get the rewardAmount (remaining deposit)
     *   - the targetAccount will pay for the rewardAmount
     * - if the targetAccount is insolvent
     *   - the liquidatorAccount will get the rewardAmount (single deposit)
     *   - the default reward account (governance) will pay for both the rewardAmount and bailoutAmount
     *   - the targetAccount will receive the bailoutAmount
     */
    event AgreementLiquidatedV2(
        address indexed agreementClass,
        bytes32 id,
        address indexed liquidatorAccount,
        address indexed targetAccount,
        address rewardAmountReceiver,
        uint256 rewardAmount,
        int256 targetAccountBalanceDelta,
        bytes liquidationTypeData
    );

    /**************************************************************************
     * Function modifiers for access control and parameter validations
     *
     * While they cannot be explicitly stated in function definitions, they are
     * listed in function definition comments instead for clarity.
     *
     * NOTE: solidity-coverage not supporting it
     *************************************************************************/

     /// @dev The msg.sender must be host contract
     //modifier onlyHost() virtual;

    /// @dev The msg.sender must be a listed agreement.
    //modifier onlyAgreement() virtual;

    /**************************************************************************
     * DEPRECATED
     *************************************************************************/

    /**
     * @dev Agreement liquidation event (DEPRECATED BY AgreementLiquidatedBy)
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @param penaltyAccount Account of the agreement to be penalized
     * @param rewardAccount Account that collect the reward
     * @param rewardAmount Amount of liquidation reward
     *
     * @custom:deprecated Use AgreementLiquidatedV2 instead
     */
    event AgreementLiquidated(
        address indexed agreementClass,
        bytes32 id,
        address indexed penaltyAccount,
        address indexed rewardAccount,
        uint256 rewardAmount
    );

    /**
     * @dev System bailout occurred (DEPRECATED BY AgreementLiquidatedBy)
     * @param bailoutAccount Account that bailout the penalty account
     * @param bailoutAmount Amount of account bailout
     *
     * @custom:deprecated Use AgreementLiquidatedV2 instead
     */
    event Bailout(
        address indexed bailoutAccount,
        uint256 bailoutAmount
    );

    /**
     * @dev Agreement liquidation event (DEPRECATED BY AgreementLiquidatedV2)
     * @param liquidatorAccount Account of the agent that performed the liquidation.
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @param penaltyAccount Account of the agreement to be penalized
     * @param bondAccount Account that collect the reward or bailout accounts
     * @param rewardAmount Amount of liquidation reward
     * @param bailoutAmount Amount of liquidation bailouot
     *
     * @custom:deprecated Use AgreementLiquidatedV2 instead
     *
     * @custom:note 
     * Reward account rule:
     * - if bailout is equal to 0, then
     *   - the bondAccount will get the rewardAmount,
     *   - the penaltyAccount will pay for the rewardAmount.
     * - if bailout is larger than 0, then
     *   - the liquidatorAccount will get the rewardAmouont,
     *   - the bondAccount will pay for both the rewardAmount and bailoutAmount,
     *   - the penaltyAccount will pay for the rewardAmount while get the bailoutAmount.
     */
    event AgreementLiquidatedBy(
        address liquidatorAccount,
        address indexed agreementClass,
        bytes32 id,
        address indexed penaltyAccount,
        address indexed bondAccount,
        uint256 rewardAmount,
        uint256 bailoutAmount
    );
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.4;

import { ISuperfluid } from "./ISuperfluid.sol";
import { ISuperfluidToken } from "./ISuperfluidToken.sol";
import { TokenInfo } from "../tokens/TokenInfo.sol";
import { IERC777 } from "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SuperfluidErrors } from "./Definitions.sol";

/**
 * @title Super token (Superfluid Token + ERC20 + ERC777) interface
 * @author Superfluid
 */
interface ISuperToken is ISuperfluidToken, TokenInfo, IERC20, IERC777 {

    /**************************************************************************
     * Errors
     *************************************************************************/
    error SUPER_TOKEN_CALLER_IS_NOT_OPERATOR_FOR_HOLDER();
    error SUPER_TOKEN_NOT_ERC777_TOKENS_RECIPIENT();
    error SUPER_TOKEN_INFLATIONARY_DEFLATIONARY_NOT_SUPPORTED();
    error SUPER_TOKEN_NO_UNDERLYING_TOKEN();
    error SUPER_TOKEN_ONLY_SELF();

    /**
     * @dev Initialize the contract
     */
    function initialize(
        IERC20 underlyingToken,
        uint8 underlyingDecimals,
        string calldata n,
        string calldata s
    ) external;

    /**************************************************************************
    * TokenInfo & ERC777
    *************************************************************************/

    /**
     * @dev Returns the name of the token.
     */
    function name() external view override(IERC777, TokenInfo) returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view override(IERC777, TokenInfo) returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * @custom:note SuperToken always uses 18 decimals.
     *
     * This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view override(TokenInfo) returns (uint8);

    /**************************************************************************
    * ERC20 & ERC777
    *************************************************************************/

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view override(IERC777, IERC20) returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address account) external view override(IERC777, IERC20) returns(uint256 balance);

    /**************************************************************************
    * ERC20
    *************************************************************************/

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * @return Returns Success a boolean value indicating whether the operation succeeded.
     *
     * @custom:emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external override(IERC20) returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     *         allowed to spend on behalf of `owner` through {transferFrom}. This is
     *         zero by default.
     *
     * @notice This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external override(IERC20) view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * @return Returns Success a boolean value indicating whether the operation succeeded.
     *
     * @custom:note Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * @custom:emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external override(IERC20) returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     *         allowance mechanism. `amount` is then deducted from the caller's
     *         allowance.
     *
     * @return Returns Success a boolean value indicating whether the operation succeeded.
     *
     * @custom:emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external override(IERC20) returns (bool);

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * @custom:emits an {Approval} event indicating the updated allowance.
     *
     * @custom:requirements 
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * @custom:emits an {Approval} event indicating the updated allowance.
     *
     * @custom:requirements 
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
     function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /**************************************************************************
    * ERC777
    *************************************************************************/

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     *         means all token operations (creation, movement and destruction) must have
     *         amounts that are a multiple of this number.
     *
     * @custom:note For super token contracts, this value is always 1
     */
    function granularity() external view override(IERC777) returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * @dev If send or receive hooks are registered for the caller and `recipient`,
     *      the corresponding functions will be called with `data` and empty
     *      `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * @custom:emits a {Sent} event.
     *
     * @custom:requirements 
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(address recipient, uint256 amount, bytes calldata data) external override(IERC777);

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * @custom:emits a {Burned} event.
     *
     * @custom:requirements 
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external override(IERC777);

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external override(IERC777) view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * @custom:emits an {AuthorizedOperator} event.
     *
     * @custom:requirements 
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external override(IERC777);

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * @custom:emits a {RevokedOperator} event.
     *
     * @custom:requirements 
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external override(IERC777);

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external override(IERC777) view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * @custom:emits a {Sent} event.
     *
     * @custom:requirements 
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external override(IERC777);

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * @custom:emits a {Burned} event.
     *
     * @custom:requirements 
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external override(IERC777);

    /**************************************************************************
     * SuperToken custom token functions
     *************************************************************************/

    /**
     * @dev Mint new tokens for the account
     *
     * @custom:modifiers 
     *  - onlySelf
     */
    function selfMint(
        address account,
        uint256 amount,
        bytes memory userData
    ) external;

   /**
    * @dev Burn existing tokens for the account
    *
    * @custom:modifiers 
    *  - onlySelf
    */
   function selfBurn(
       address account,
       uint256 amount,
       bytes memory userData
   ) external;

   /**
    * @dev Transfer `amount` tokens from the `sender` to `recipient`.
    * If `spender` isn't the same as `sender`, checks if `spender` has allowance to
    * spend tokens of `sender`.
    *
    * @custom:modifiers 
    *  - onlySelf
    */
   function selfTransferFrom(
        address sender,
        address spender,
        address recipient,
        uint256 amount
   ) external;

   /**
    * @dev Give `spender`, `amount` allowance to spend the tokens of
    * `account`.
    *
    * @custom:modifiers 
    *  - onlySelf
    */
   function selfApproveFor(
        address account,
        address spender,
        uint256 amount
   ) external;

    /**************************************************************************
     * SuperToken extra functions
     *************************************************************************/

    /**
     * @dev Transfer all available balance from `msg.sender` to `recipient`
     */
    function transferAll(address recipient) external;

    /**************************************************************************
     * ERC20 wrapping
     *************************************************************************/

    /**
     * @dev Return the underlying token contract
     * @return tokenAddr Underlying token address
     */
    function getUnderlyingToken() external view returns(address tokenAddr);

    /**
     * @dev Upgrade ERC20 to SuperToken.
     * @param amount Number of tokens to be upgraded (in 18 decimals)
     *
     * @custom:note It will use `transferFrom` to get tokens. Before calling this
     * function you should `approve` this contract
     */
    function upgrade(uint256 amount) external;

    /**
     * @dev Upgrade ERC20 to SuperToken and transfer immediately
     * @param to The account to received upgraded tokens
     * @param amount Number of tokens to be upgraded (in 18 decimals)
     * @param data User data for the TokensRecipient callback
     *
     * @custom:note It will use `transferFrom` to get tokens. Before calling this
     * function you should `approve` this contract
     */
    function upgradeTo(address to, uint256 amount, bytes calldata data) external;

    /**
     * @dev Token upgrade event
     * @param account Account where tokens are upgraded to
     * @param amount Amount of tokens upgraded (in 18 decimals)
     */
    event TokenUpgraded(
        address indexed account,
        uint256 amount
    );

    /**
     * @dev Downgrade SuperToken to ERC20.
     * @dev It will call transfer to send tokens
     * @param amount Number of tokens to be downgraded
     */
    function downgrade(uint256 amount) external;

    /**
     * @dev Token downgrade event
     * @param account Account whose tokens are upgraded
     * @param amount Amount of tokens downgraded
     */
    event TokenDowngraded(
        address indexed account,
        uint256 amount
    );

    /**************************************************************************
    * Batch Operations
    *************************************************************************/

    /**
    * @dev Perform ERC20 approve by host contract.
    * @param account The account owner to be approved.
    * @param spender The spender of account owner's funds.
    * @param amount Number of tokens to be approved.
    *
    * @custom:modifiers 
    *  - onlyHost
    */
    function operationApprove(
        address account,
        address spender,
        uint256 amount
    ) external;

    /**
    * @dev Perform ERC20 transfer from by host contract.
    * @param account The account to spend sender's funds.
    * @param spender  The account where the funds is sent from.
    * @param recipient The recipient of thefunds.
    * @param amount Number of tokens to be transferred.
    *
    * @custom:modifiers 
    *  - onlyHost
    */
    function operationTransferFrom(
        address account,
        address spender,
        address recipient,
        uint256 amount
    ) external;

    /**
    * @dev Upgrade ERC20 to SuperToken by host contract.
    * @param account The account to be changed.
    * @param amount Number of tokens to be upgraded (in 18 decimals)
    *
    * @custom:modifiers 
    *  - onlyHost
    */
    function operationUpgrade(address account, uint256 amount) external;

    /**
    * @dev Downgrade ERC20 to SuperToken by host contract.
    * @param account The account to be changed.
    * @param amount Number of tokens to be downgraded (in 18 decimals)
    *
    * @custom:modifiers 
    *  - onlyHost
    */
    function operationDowngrade(address account, uint256 amount) external;


    /**************************************************************************
    * Function modifiers for access control and parameter validations
    *
    * While they cannot be explicitly stated in function definitions, they are
    * listed in function definition comments instead for clarity.
    *
    * NOTE: solidity-coverage not supporting it
    *************************************************************************/

    /// @dev The msg.sender must be the contract itself
    //modifier onlySelf() virtual

}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.4;

import { ISuperfluidToken } from "./ISuperfluidToken.sol";

/**
 * @title Super agreement interface
 * @author Superfluid
 */
interface ISuperAgreement {

    /**
     * @dev Get the type of the agreement class
     */
    function agreementType() external view returns (bytes32);

    /**
     * @dev Calculate the real-time balance for the account of this agreement class
     * @param account Account the state belongs to
     * @param time Time used for the calculation
     * @return dynamicBalance Dynamic balance portion of real-time balance of this agreement
     * @return deposit Account deposit amount of this agreement
     * @return owedDeposit Account owed deposit amount of this agreement
     */
    function realtimeBalanceOf(
        ISuperfluidToken token,
        address account,
        uint256 time
    )
        external
        view
        returns (
            int256 dynamicBalance,
            uint256 deposit,
            uint256 owedDeposit
        );

}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.4;

import { ISuperToken } from "./ISuperToken.sol";

/**
 * @title SuperApp interface
 * @author Superfluid
 * @dev Be aware of the app being jailed, when the word permitted is used.
 */
interface ISuperApp {

    /**
     * @dev Callback before a new agreement is created.
     * @param superToken The super token used for the agreement.
     * @param agreementClass The agreement class address.
     * @param agreementId The agreementId
     * @param agreementData The agreement data (non-compressed)
     * @param ctx The context data.
     * @return cbdata A free format in memory data the app can use to pass
     *          arbitary information to the after-hook callback.
     *
     * @custom:note 
     * - It will be invoked with `staticcall`, no state changes are permitted.
     * - Only revert with a "reason" is permitted.
     */
    function beforeAgreementCreated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata ctx
    )
        external
        view
        returns (bytes memory cbdata);

    /**
     * @dev Callback after a new agreement is created.
     * @param superToken The super token used for the agreement.
     * @param agreementClass The agreement class address.
     * @param agreementId The agreementId
     * @param agreementData The agreement data (non-compressed)
     * @param cbdata The data returned from the before-hook callback.
     * @param ctx The context data.
     * @return newCtx The current context of the transaction.
     *
     * @custom:note 
     * - State changes is permitted.
     * - Only revert with a "reason" is permitted.
     */
    function afterAgreementCreated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata cbdata,
        bytes calldata ctx
    )
        external
        returns (bytes memory newCtx);

    /**
     * @dev Callback before a new agreement is updated.
     * @param superToken The super token used for the agreement.
     * @param agreementClass The agreement class address.
     * @param agreementId The agreementId
     * @param agreementData The agreement data (non-compressed)
     * @param ctx The context data.
     * @return cbdata A free format in memory data the app can use to pass
     *          arbitary information to the after-hook callback.
     *
     * @custom:note 
     * - It will be invoked with `staticcall`, no state changes are permitted.
     * - Only revert with a "reason" is permitted.
     */
    function beforeAgreementUpdated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata ctx
    )
        external
        view
        returns (bytes memory cbdata);


    /**
    * @dev Callback after a new agreement is updated.
    * @param superToken The super token used for the agreement.
    * @param agreementClass The agreement class address.
    * @param agreementId The agreementId
    * @param agreementData The agreement data (non-compressed)
    * @param cbdata The data returned from the before-hook callback.
    * @param ctx The context data.
    * @return newCtx The current context of the transaction.
    *
    * @custom:note 
    * - State changes is permitted.
    * - Only revert with a "reason" is permitted.
    */
    function afterAgreementUpdated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata cbdata,
        bytes calldata ctx
    )
        external
        returns (bytes memory newCtx);

    /**
    * @dev Callback before a new agreement is terminated.
    * @param superToken The super token used for the agreement.
    * @param agreementClass The agreement class address.
    * @param agreementId The agreementId
    * @param agreementData The agreement data (non-compressed)
    * @param ctx The context data.
    * @return cbdata A free format in memory data the app can use to pass arbitary information to the after-hook callback.
    *
    * @custom:note 
    * - It will be invoked with `staticcall`, no state changes are permitted.
    * - Revert is not permitted.
    */
    function beforeAgreementTerminated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata ctx
    )
        external
        view
        returns (bytes memory cbdata);

    /**
    * @dev Callback after a new agreement is terminated.
    * @param superToken The super token used for the agreement.
    * @param agreementClass The agreement class address.
    * @param agreementId The agreementId
    * @param agreementData The agreement data (non-compressed)
    * @param cbdata The data returned from the before-hook callback.
    * @param ctx The context data.
    * @return newCtx The current context of the transaction.
    *
    * @custom:note 
    * - State changes is permitted.
    * - Revert is not permitted.
    */
    function afterAgreementTerminated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata cbdata,
        bytes calldata ctx
    )
        external
        returns (bytes memory newCtx);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.4;

/**
 * @title ERC20 token info interface
 * @author Superfluid
 * @dev ERC20 standard interface does not specify these functions, but
 *      often the token implementations have them.
 */
interface TokenInfo {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.4;

import { ISuperToken } from "./ISuperToken.sol";

import {
    IERC20,
    ERC20WithTokenInfo
} from "../tokens/ERC20WithTokenInfo.sol";
import { SuperfluidErrors } from "./Definitions.sol";

/**
 * @title Super token factory interface
 * @author Superfluid
 */
interface ISuperTokenFactory {
    /**
     * @dev Get superfluid host contract address
     */
    function getHost() external view returns(address host);

    /// @dev Initialize the contract
    function initialize() external;

    /**
     * @dev Get the current super token logic used by the factory
     */
    function getSuperTokenLogic() external view returns (ISuperToken superToken);

    /**
     * @dev Upgradability modes
     */
    enum Upgradability {
        /// Non upgradable super token, `host.updateSuperTokenLogic` will revert
        NON_UPGRADABLE,
        /// Upgradable through `host.updateSuperTokenLogic` operation
        SEMI_UPGRADABLE,
        /// Always using the latest super token logic
        FULL_UPGRADABE
    }

    /**
     * @dev Create new super token wrapper for the underlying ERC20 token
     * @param underlyingToken Underlying ERC20 token
     * @param underlyingDecimals Underlying token decimals
     * @param upgradability Upgradability mode
     * @param name Super token name
     * @param symbol Super token symbol
     */
    function createERC20Wrapper(
        IERC20 underlyingToken,
        uint8 underlyingDecimals,
        Upgradability upgradability,
        string calldata name,
        string calldata symbol
    )
        external
        returns (ISuperToken superToken);

    /**
     * @dev Create new super token wrapper for the underlying ERC20 token with extra token info
     * @param underlyingToken Underlying ERC20 token
     * @param upgradability Upgradability mode
     * @param name Super token name
     * @param symbol Super token symbol
     *
     * NOTE:
     * - It assumes token provide the .decimals() function
     */
    function createERC20Wrapper(
        ERC20WithTokenInfo underlyingToken,
        Upgradability upgradability,
        string calldata name,
        string calldata symbol
    )
        external
        returns (ISuperToken superToken);

    function initializeCustomSuperToken(
        address customSuperTokenProxy
    )
        external;

    /**
      * @dev Super token logic created event
      * @param tokenLogic Token logic address
      */
    event SuperTokenLogicCreated(ISuperToken indexed tokenLogic);

    /**
      * @dev Super token created event
      * @param token Newly created super token address
      */
    event SuperTokenCreated(ISuperToken indexed token);

    /**
      * @dev Custom super token created event
      * @param token Newly created custom super token address
      */
    event CustomSuperTokenCreated(ISuperToken indexed token);

}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.4;

/**
 * @title Super app definitions library
 * @author Superfluid
 */
library SuperAppDefinitions {

    /**************************************************************************
    / App manifest config word
    /**************************************************************************/

    /*
     * App level is a way to allow the app to whitelist what other app it can
     * interact with (aka. composite app feature).
     *
     * For more details, refer to the technical paper of superfluid protocol.
     */
    uint256 constant internal APP_LEVEL_MASK = 0xFF;

    // The app is at the final level, hence it doesn't want to interact with any other app
    uint256 constant internal APP_LEVEL_FINAL = 1 << 0;

    // The app is at the second level, it may interact with other final level apps if whitelisted
    uint256 constant internal APP_LEVEL_SECOND = 1 << 1;

    function getAppCallbackLevel(uint256 configWord) internal pure returns (uint8) {
        return uint8(configWord & APP_LEVEL_MASK);
    }

    uint256 constant internal APP_JAIL_BIT = 1 << 15;
    function isAppJailed(uint256 configWord) internal pure returns (bool) {
        return (configWord & SuperAppDefinitions.APP_JAIL_BIT) > 0;
    }

    /**************************************************************************
    / Callback implementation bit masks
    /**************************************************************************/
    uint256 constant internal AGREEMENT_CALLBACK_NOOP_BITMASKS = 0xFF << 32;
    uint256 constant internal BEFORE_AGREEMENT_CREATED_NOOP = 1 << (32 + 0);
    uint256 constant internal AFTER_AGREEMENT_CREATED_NOOP = 1 << (32 + 1);
    uint256 constant internal BEFORE_AGREEMENT_UPDATED_NOOP = 1 << (32 + 2);
    uint256 constant internal AFTER_AGREEMENT_UPDATED_NOOP = 1 << (32 + 3);
    uint256 constant internal BEFORE_AGREEMENT_TERMINATED_NOOP = 1 << (32 + 4);
    uint256 constant internal AFTER_AGREEMENT_TERMINATED_NOOP = 1 << (32 + 5);

    /**************************************************************************
    / App Jail Reasons
    /**************************************************************************/

    uint256 constant internal APP_RULE_REGISTRATION_ONLY_IN_CONSTRUCTOR = 1;
    uint256 constant internal APP_RULE_NO_REGISTRATION_FOR_EOA = 2;
    uint256 constant internal APP_RULE_NO_REVERT_ON_TERMINATION_CALLBACK = 10;
    uint256 constant internal APP_RULE_NO_CRITICAL_SENDER_ACCOUNT = 11;
    uint256 constant internal APP_RULE_NO_CRITICAL_RECEIVER_ACCOUNT = 12;
    uint256 constant internal APP_RULE_CTX_IS_READONLY = 20;
    uint256 constant internal APP_RULE_CTX_IS_NOT_CLEAN = 21;
    uint256 constant internal APP_RULE_CTX_IS_MALFORMATED = 22;
    uint256 constant internal APP_RULE_COMPOSITE_APP_IS_NOT_WHITELISTED = 30;
    uint256 constant internal APP_RULE_COMPOSITE_APP_IS_JAILED = 31;
    uint256 constant internal APP_RULE_MAX_APP_LEVEL_REACHED = 40;

    // Validate configWord cleaness for future compatibility, or else may introduce undefined future behavior
    function isConfigWordClean(uint256 configWord) internal pure returns (bool) {
        return (configWord & ~(APP_LEVEL_MASK | APP_JAIL_BIT | AGREEMENT_CALLBACK_NOOP_BITMASKS)) == uint256(0);
    }
}

/**
 * @title Context definitions library
 * @author Superfluid
 */
library ContextDefinitions {

    /**************************************************************************
    / Call info
    /**************************************************************************/

    // app level
    uint256 constant internal CALL_INFO_APP_LEVEL_MASK = 0xFF;

    // call type
    uint256 constant internal CALL_INFO_CALL_TYPE_SHIFT = 32;
    uint256 constant internal CALL_INFO_CALL_TYPE_MASK = 0xF << CALL_INFO_CALL_TYPE_SHIFT;
    uint8 constant internal CALL_INFO_CALL_TYPE_AGREEMENT = 1;
    uint8 constant internal CALL_INFO_CALL_TYPE_APP_ACTION = 2;
    uint8 constant internal CALL_INFO_CALL_TYPE_APP_CALLBACK = 3;

    function decodeCallInfo(uint256 callInfo)
        internal pure
        returns (uint8 appCallbackLevel, uint8 callType)
    {
        appCallbackLevel = uint8(callInfo & CALL_INFO_APP_LEVEL_MASK);
        callType = uint8((callInfo & CALL_INFO_CALL_TYPE_MASK) >> CALL_INFO_CALL_TYPE_SHIFT);
    }

    function encodeCallInfo(uint8 appCallbackLevel, uint8 callType)
        internal pure
        returns (uint256 callInfo)
    {
        return uint256(appCallbackLevel) | (uint256(callType) << CALL_INFO_CALL_TYPE_SHIFT);
    }

}

/**
 * @title Flow Operator definitions library
  * @author Superfluid
 */
 library FlowOperatorDefinitions {
    uint8 constant internal AUTHORIZE_FLOW_OPERATOR_CREATE = uint8(1) << 0;
    uint8 constant internal AUTHORIZE_FLOW_OPERATOR_UPDATE = uint8(1) << 1;
    uint8 constant internal AUTHORIZE_FLOW_OPERATOR_DELETE = uint8(1) << 2;
    uint8 constant internal AUTHORIZE_FULL_CONTROL =
        AUTHORIZE_FLOW_OPERATOR_CREATE | AUTHORIZE_FLOW_OPERATOR_UPDATE | AUTHORIZE_FLOW_OPERATOR_DELETE;
    uint8 constant internal REVOKE_FLOW_OPERATOR_CREATE = ~(uint8(1) << 0);
    uint8 constant internal REVOKE_FLOW_OPERATOR_UPDATE = ~(uint8(1) << 1);
    uint8 constant internal REVOKE_FLOW_OPERATOR_DELETE = ~(uint8(1) << 2);

    function isPermissionsClean(uint8 permissions) internal pure returns (bool) {
        return (
            permissions & ~(AUTHORIZE_FLOW_OPERATOR_CREATE
                | AUTHORIZE_FLOW_OPERATOR_UPDATE
                | AUTHORIZE_FLOW_OPERATOR_DELETE)
            ) == uint8(0);
    }
 }

/**
 * @title Batch operation library
 * @author Superfluid
 */
library BatchOperation {
    /**
     * @dev ERC20.approve batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationApprove(
     *     abi.decode(data, (address spender, uint256 amount))
     * )
     */
    uint32 constant internal OPERATION_TYPE_ERC20_APPROVE = 1;
    /**
     * @dev ERC20.transferFrom batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationTransferFrom(
     *     abi.decode(data, (address sender, address recipient, uint256 amount)
     * )
     */
    uint32 constant internal OPERATION_TYPE_ERC20_TRANSFER_FROM = 2;
    /**
     * @dev SuperToken.upgrade batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationUpgrade(
     *     abi.decode(data, (uint256 amount)
     * )
     */
    uint32 constant internal OPERATION_TYPE_SUPERTOKEN_UPGRADE = 1 + 100;
    /**
     * @dev SuperToken.downgrade batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationDowngrade(
     *     abi.decode(data, (uint256 amount)
     * )
     */
    uint32 constant internal OPERATION_TYPE_SUPERTOKEN_DOWNGRADE = 2 + 100;
    /**
     * @dev Superfluid.callAgreement batch operation type
     *
     * Call spec:
     * callAgreement(
     *     ISuperAgreement(target)),
     *     abi.decode(data, (bytes calldata, bytes userdata)
     * )
     */
    uint32 constant internal OPERATION_TYPE_SUPERFLUID_CALL_AGREEMENT = 1 + 200;
    /**
     * @dev Superfluid.callAppAction batch operation type
     *
     * Call spec:
     * callAppAction(
     *     ISuperApp(target)),
     *     data
     * )
     */
    uint32 constant internal OPERATION_TYPE_SUPERFLUID_CALL_APP_ACTION = 2 + 200;
}

/**
 * @title Superfluid governance configs library
 * @author Superfluid
 */
library SuperfluidGovernanceConfigs {

    bytes32 constant internal SUPERFLUID_REWARD_ADDRESS_CONFIG_KEY =
        keccak256("org.superfluid-finance.superfluid.rewardAddress");
    bytes32 constant internal CFAV1_PPP_CONFIG_KEY =
        keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1.PPPConfiguration");
    bytes32 constant internal SUPERTOKEN_MINIMUM_DEPOSIT_KEY =
        keccak256("org.superfluid-finance.superfluid.superTokenMinimumDeposit");

    function getTrustedForwarderConfigKey(address forwarder) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            "org.superfluid-finance.superfluid.trustedForwarder",
            forwarder));
    }

    function getAppRegistrationConfigKey(address deployer, string memory registrationKey) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            "org.superfluid-finance.superfluid.appWhiteListing.registrationKey",
            deployer,
            registrationKey));
    }

    function getAppFactoryConfigKey(address factory) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            "org.superfluid-finance.superfluid.appWhiteListing.factory",
            factory));
    }

    function decodePPPConfig(uint256 pppConfig) internal pure returns (uint256 liquidationPeriod, uint256 patricianPeriod) {
        liquidationPeriod = (pppConfig >> 32) & type(uint32).max;
        patricianPeriod = pppConfig & type(uint32).max;
    }
}

/**
 * @title Superfluid Common Custom Errors and Error Codes
 * @author Superfluid
 */
library SuperfluidErrors {
    /**************************************************************************
    / Shared Custom Errors
    /**************************************************************************/
    error APP_RULE(uint256 _code); // uses SuperAppDefinitions' App Jail Reasons

    // The Error Code Reference refers to the types of errors within a range,
    // e.g. ALREADY_EXISTS and DOES_NOT_EXIST error codes will live between
    // 1000-1099 for Constant Flow Agreement error codes.

                                                 // Error Code Reference
    error ALREADY_EXISTS(uint256 _code);         // 0 - 99
    error DOES_NOT_EXIST(uint256 _code);         // 0 - 99
    error INSUFFICIENT_BALANCE(uint256 _code);   // 100 - 199
    error MUST_BE_CONTRACT(uint256 _code);       // 200 - 299
    error ONLY_LISTED_AGREEMENT(uint256 _code);  // 300 - 399
    error ONLY_HOST(uint256 _code);              // 400 - 499
    error ZERO_ADDRESS(uint256 _code);           // 500 - 599

    /**************************************************************************
    / Error Codes
    /**************************************************************************/
    // 1000 - 1999 | Constant Flow Agreement
    uint256 constant internal CFA_FLOW_ALREADY_EXISTS = 1000;
    uint256 constant internal CFA_FLOW_DOES_NOT_EXIST = 1001;

    uint256 constant internal CFA_INSUFFICIENT_BALANCE = 1100;

    uint256 constant internal CFA_ZERO_ADDRESS_SENDER = 1500;
    uint256 constant internal CFA_ZERO_ADDRESS_RECEIVER = 1501;

    // 2000 - 2999 | Instant Distribution Agreement
    uint256 constant internal IDA_INDEX_ALREADY_EXISTS = 2000;
    uint256 constant internal IDA_INDEX_DOES_NOT_EXIST = 2001;

    uint256 constant internal IDA_SUBSCRIPTION_DOES_NOT_EXIST = 2002;

    uint256 constant internal IDA_SUBSCRIPTION_ALREADY_APPROVED = 2003;
    uint256 constant internal IDA_SUBSCRIPTION_IS_NOT_APPROVED = 2004;

    uint256 constant internal IDA_INSUFFICIENT_BALANCE = 2100;

    uint256 constant internal IDA_ZERO_ADDRESS_SUBSCRIBER = 2500;
    
    // 3000 - 3999 | Host
    uint256 constant internal HOST_AGREEMENT_ALREADY_REGISTERED = 3000;
    uint256 constant internal HOST_AGREEMENT_IS_NOT_REGISTERED = 3001;
    uint256 constant internal HOST_SUPER_APP_ALREADY_REGISTERED = 3002;
    
    uint256 constant internal HOST_MUST_BE_CONTRACT = 3200;

    uint256 constant internal HOST_ONLY_LISTED_AGREEMENT = 3300;

    // 4000 - 4999 | Superfluid Governance II
    uint256 constant internal SF_GOV_MUST_BE_CONTRACT = 4200;

    // 5000 - 5999 | SuperfluidToken
    uint256 constant internal SF_TOKEN_AGREEMENT_ALREADY_EXISTS = 5000;
    uint256 constant internal SF_TOKEN_AGREEMENT_DOES_NOT_EXIST = 5001;

    uint256 constant internal SF_TOKEN_BURN_INSUFFICIENT_BALANCE = 5100;
    uint256 constant internal SF_TOKEN_MOVE_INSUFFICIENT_BALANCE = 5101;

    uint256 constant internal SF_TOKEN_ONLY_LISTED_AGREEMENT = 5300;

    uint256 constant internal SF_TOKEN_ONLY_HOST = 5400;
    
    // 6000 - 6999 | SuperToken
    uint256 constant internal SUPER_TOKEN_ONLY_HOST = 6400;

    uint256 constant internal SUPER_TOKEN_APPROVE_FROM_ZERO_ADDRESS = 6500;
    uint256 constant internal SUPER_TOKEN_APPROVE_TO_ZERO_ADDRESS = 6501;
    uint256 constant internal SUPER_TOKEN_BURN_FROM_ZERO_ADDRESS = 6502;
    uint256 constant internal SUPER_TOKEN_MINT_TO_ZERO_ADDRESS = 6503;
    uint256 constant internal SUPER_TOKEN_TRANSFER_FROM_ZERO_ADDRESS = 6504;
    uint256 constant internal SUPER_TOKEN_TRANSFER_TO_ZERO_ADDRESS = 6505;

    // 7000 - 7999 | SuperToken Factory
    uint256 constant internal SUPER_TOKEN_FACTORY_ONLY_HOST = 7400;

    uint256 constant internal SUPER_TOKEN_FACTORY_ZERO_ADDRESS = 7500;

    // 8000 - 8999 | Agreement Base
    uint256 constant internal AGREEMENT_BASE_ONLY_HOST = 8400;
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.4;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { TokenInfo } from "./TokenInfo.sol";

/**
 * @title ERC20 token with token info interface
 * @author Superfluid
 * @dev Using abstract contract instead of interfaces because old solidity
 *      does not support interface inheriting other interfaces
 * solhint-disable-next-line no-empty-blocks
 *
 */
// solhint-disable-next-line no-empty-blocks
abstract contract ERC20WithTokenInfo is IERC20, TokenInfo {}