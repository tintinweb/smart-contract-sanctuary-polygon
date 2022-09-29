// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./objects/ParadimeTokens.sol";
import "./objects/BundleDefinition.sol";
import "./ArtistAgreement.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol"; 
/**

    1. Project Admins Access Control
    2. Retrieve Roylaties
    3. Retrieve Permissions
    4. Enforce Balance
 */
contract DigitalAudioTracks is ERC1155 {
    using Counters for Counters.Counter;
    using ParadimeTokens for ParadimeTokens.TokenDefinition;
    //Roles
    bytes32 private constant STREAM_PROVIDER_ROLE = keccak256("PROVIDER");
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 private constant APPROVED_ISSUER = keccak256("ISSUER");
    //Share Definition
    // struct Shares {
    //     address payable entity;
    //     uint16 allocation;
    // }
    //Token Consumption
    event TokenIssued(
        uint256 tokenId,
        uint32 launchDate,
        address indexed issuer
    );

    event BundleIssued(
        uint256 bundleId,
        uint32 launchDate,
        address indexed issuer
    );

    //Admin
    mapping(bytes32 => mapping(address => bool)) private roleDeligations; 
    //Tokens
    string private baseURI;
    mapping(bytes32 => ParadimeTokens.TokenDefinition) private tokens;
    mapping(bytes32 => ArtistAgreement) private artistAgreements;
    //mapping(uint256 => BundleDefinition.Bundle) private bundles;
    Counters.Counter public issuedTokens;
    //Counters.Counter public issuedBundles;
    mapping(uint256 => mapping(address => uint256)) balances;
    mapping(bytes32 => uint256) private projectToTokens;
    // Mapping from token ID to approved address
    mapping(uint => address) private _tokenApprovals;
    // All owners

    //Fees
    uint256 private standardTokenFee; 
    mapping(address => uint256) private registeredTokenFees;
    uint256 private standardBundleFee; 
    mapping(address => uint256) private registeredBundleFees;
    uint256 private stanardRoyalty;
    mapping(address => uint256) private registeredRoyalties;
    uint256 private standardMintingPercentage = 15;
    mapping(uint256 => uint256) private registeredMintingPercentage;

    constructor(
        //string memory _baseURI//, 
        // uint256 _standardTokenFee,
        // uint256 _standardBundleFee,
        // uint256 _stanardRoyalty//,
        //address[] memory _admins
        
    )  ERC1155("https://app.paradimeaudio.com/api/NFT/DAT/Token/{id}.json")  {
        baseURI = "https://app.paradimeaudio.com/api/NFT/DAT/Token/{id}.json";//_baseURI;
        standardTokenFee = 1 ether;//_standardTokenFee;
        standardBundleFee = 15;//_standardBundleFee;
        stanardRoyalty = 1 ether;//_stanardRoyalty;
        //TODO: Set up Roles
        roleDeligations[ADMIN_ROLE][msg.sender] = true;
        roleDeligations[APPROVED_ISSUER][msg.sender] = true;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }    

    modifier isTokenIssuer(bytes32 _tokenId) {
        //require(tokens[_tokenId].issuers.isIssuer[msg.sender], "Only the issuers of this token can access this information");
        _;
    }

    modifier onlyProjectAdmin() {
        require(roleDeligations[ADMIN_ROLE][msg.sender], "Only admins can perform this action");
        _;
    }

    function balanceOf(address owner, bytes32 _tokenId) public view returns (uint) {
        require(owner != address(0), "owner = zero address");
        return balances[projectToTokens[_tokenId]][owner];
    }

    //onlyProjectAdmin

    function approveIssuer(address _newAdmin) public onlyProjectAdmin {
        //APPROVED_ISSUER
        roleDeligations[APPROVED_ISSUER][msg.sender] = true;
    }

    // function issuerOf(uint tokenId) tokenExists(_tokenId) public view override returns (address[] owners) {
    //     owners = tokens[tokenId].issuer;
    //     require(owner != address(0), "token doesn't exist");
    // }

    // function creatorsOf(bytes32 _tokenId) tokenExists(_tokenId) public view returns (address[] memory res) {
    //     res = tokens[tokenId].getIssuers();
    //     return res;
    // }
    //isTokenIssuer(_tokenId) 
    function getOwnershipStake(bytes32 _tokenId, address _issuer) tokenExists(_tokenId) public view returns (uint256) {
        return ArtistAgreement(tokens[_tokenId].owner).getOwnerStake(_issuer);
    }

    modifier tokenExists(bytes32 _tokenId) {
        require(tokens[_tokenId].owner != address(0), "This token has not been issued yet.");
        _;
    }

    function issueToken(
        bytes32 _projectId,
        //Shares
        ParadimeTokens.Shares[] memory _owners,
        ParadimeTokens.Shares[] memory _residualOwners,
        //Allocation
        ParadimeTokens.ListingDetails memory listing,
        uint _exportRoyalty,
        uint _sampleRoyalty,
        uint _remixRoyalty,
        uint _resaleRoyalty//,
        // //Permissions
        // bool _publishPermission,
        // bool _exportPermission,
        // bool _samplePermission,
        // bool _remixPermission
    ) public { //onlyProjectAdmin payable
        //require(roleDeligations[ADMIN_ROLE][msg.sender], "Only");
        // (bool paymentSuccess, ) = payable(address(this)).call{ value: standardTokenFee}("");
        // require(paymentSuccess, "Payment was not successful");
        //{
            // ArtistAgreement _agreement = new ArtistAgreement(
            //     address(this),
            //     _owners,
            //     _residualOwners,
            //     _exportRoyalty,
            //     _sampleRoyalty,
            //     _remixRoyalty,
            //     _resaleRoyalty,
            //     //TODO: Permissions are hardcoded, find efficient way to unpack
            //     true,
            //     true,
            //     true,
            //     true
            // );

            //issuedTokens.increment();
            // //Enable Retrieval of Token Project by Edition#
            projectToTokens[_projectId] = issuedTokens.current();
            // tokens[_projectId] = ParadimeTokens.TokenDefinition({
            //     owner: address(this),//address(_agreement),
            //     tokenId: _projectId,
            //     listing: listing,
            //     totalMinted: 0,
            //     isPaused: false
            // });

            emit TokenIssued(
                issuedTokens.current(),
                listing.launchDate,
                msg.sender
            );

            issuedTokens.increment();
        //}
    }

    function issueBundle(
        //Editions
        uint256[] memory _tokens,
        //Bundle Price
        uint256 _price,
        uint256 _launchDate
    ) public payable {
        /**
            1. Verify Ownership of each token
            2. Create bundle definition
            3. Charge fee for issuing bundle
         */
    }

    function getArtistAgreement(bytes32 _tokenid)  public view returns (address) {
        //token
        return tokens[_tokenid].owner;
    }

    function mint(bytes32 _tokenId, uint256 _amount) tokenExists(_tokenId) public payable {
        //Make User pay gas fee
        require(_amount > 0, "The specified amount must be greater than zero");
        require(getTokenPrice(_tokenId) <= msg.value, "Incorrect amount issued");
        require(tokens[_tokenId].listing.launchDate >= block.timestamp, "This token is not ready for distribution");
        require(tokens[_tokenId].canMint(_amount));

        //Collect Payment

        ArtistAgreement _agreement = ArtistAgreement(getArtistAgreement(_tokenId));
        uint256 paradimeFee = (msg.value * standardMintingPercentage / 100);
        uint256 artistFee = (msg.value * (100 - standardMintingPercentage) / 100);
        (bool _paradimePaymentSuccess, ) = address(this).call{value : paradimeFee}("");
        bool _artistPaymentSuccess = _agreement.payOwners{value: artistFee}();//address(this).call{value : artistFee}(""); //payOwners

        if (!_paradimePaymentSuccess || !_artistPaymentSuccess) {
            revert("Payment was not successfully transfered to issuants");
        }

        //Update Supply
        tokens[_tokenId].mintAmount(_amount);
        //Mint via standard
        _mint(
            msg.sender,
            projectToTokens[_tokenId],
            _amount,
            ""
        );
        //Update Balance
        balances[projectToTokens[_tokenId]][msg.sender] += _amount;
    }

    function getTokenPrice(bytes32 _tokenId) public view returns (uint256) {
        return tokens[_tokenId].listing.price;
    }

    function getTokenAvailableSupply(bytes32 _tokenId) public view returns (uint256) {
        return tokens[_tokenId].listing.supply;
    }

    function getTokenTotalMinted(bytes32 _tokenId) public view returns (uint256) {
        return tokens[_tokenId].totalMinted;
    }

    function updateTokenPrice(bytes32 _tokenId, uint256 _price) tokenExists(_tokenId) public {
        //Make User pay gas fee
        ArtistAgreement  agreement = ArtistAgreement(tokens[_tokenId].owner);
        require(agreement.isTokenAdmin(), "Only token admins can make modifications to this token");
        tokens[_tokenId].listing.price = _price; 
        //Get Consensus 
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./objects/ParadimeTokens.sol";
import "./objects/OwnerStakes.sol";
import "./objects/TokenConsumptionTerms.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol"; 

struct UtilityToken {
    uint256 availableSupply;
    uint256 totalMinted;
    uint256 price;
    uint256 launchDate;
}

contract ArtistAgreement is ERC1155 {
    using Counters for Counters.Counter;
    using OwnerStakes for OwnerStakes.OwnerEntites;
    //Permission & Royalty Keys
    using TokenConsumptionTerms for TokenConsumptionTerms.PermissionsAndRoyalties;
    uint256 private constant OWNERSHIP_STAKE_TOKEN = 0;
    uint256 private constant RESIDUAL_STAKE_TOKEN = 1;
    address private DAT_MANAGER;
    OwnerStakes.OwnerEntites stakeHolders;
    //Token Details
    uint256 public tokenId;
    //If this token is created with other tokens
    uint256[] private references;
    bool private isPaused;
    //Transactions: UniqueId => Address => Bool (Has Been Paid)
    Counters.Counter public paymentTransactionIndex;
    //Permissions
    TokenConsumptionTerms.PermissionsAndRoyalties private usageTerms;// = TokenConsumptionTerms.PermissionsAndRoyalties({});
    //Utility Tokens: TokenType => 
    mapping (uint256 => mapping(bytes32 => mapping(address => uint256))) _tokenBalances;

    event PaymentIssued (
        uint256 invoiceNumber,
        uint256 category,
        uint256 amount,
        address owner,
        uint allocation
    );

    constructor(
        address _issuer,
        ParadimeTokens.Shares[] memory _owners,
        ParadimeTokens.Shares[] memory _residualOwners,
        // uint256 _baseTokenId,
        // uint256[] memory references,
        // //Royalties
        uint _exportRoyalty,
        uint _sampleRoyalty,
        uint _remixRoyalty,
        uint _resaleRoyalty,
        // //Permissions
        bool _publishPermission,
        bool _exportPermission,
        bool _samplePermission,
        bool _remixPermission
    ) isValidCreatorStakes(_owners, _residualOwners) 
        ERC1155("https://app.paradimeaudio.com/api/NFT/ArtistAgreement/Token/{id}.json") payable {
        //DAT_MANAGER = _manager;
        //tokenId = _baseTokenId;

        //Royalties
        //TODO Add Cover.
        usageTerms.royalties[TokenConsumptionTerms.EXPORT_ACTION] = _exportRoyalty;
        usageTerms.royalties[TokenConsumptionTerms.SAMPLE_ACTION] = _sampleRoyalty;
        usageTerms.royalties[TokenConsumptionTerms.REMIX_ACTION] = _remixRoyalty;
        usageTerms.royalties[TokenConsumptionTerms.RESELL_ACTION] = _resaleRoyalty;
        // //Permissions
        usageTerms.permissions[TokenConsumptionTerms.PUBLISH_ACTION] = _publishPermission; 
        usageTerms.permissions[TokenConsumptionTerms.EXPORT_ACTION] = _exportPermission;
        usageTerms.permissions[TokenConsumptionTerms.SAMPLE_ACTION] = _samplePermission;
        usageTerms.permissions[TokenConsumptionTerms.REMIX_ACTION] = _remixPermission; 
        //Add Admins
        _mintOwnershipTokens(_owners);
        _mintResidualRoyaltyTokens(_residualOwners);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _mintOwnershipTokens(ParadimeTokens.Shares[] memory _shares) private {
        for (uint256 i = 0; i < _shares.length; i++) {
            // _mint(
            //     _shares[i].entity,
            //     OWNERSHIP_STAKE_TOKEN,
            //     _shares[i].allocation,
            //     ""
            // );
            //usageTerms.addAdmin(_shares[i].entity);
        }
    }

    function _mintResidualRoyaltyTokens(ParadimeTokens.Shares[] memory _shares) private {
        for (uint256 i = 0; i < _shares.length; i++) {
            // _mint(
            //     _shares[i].entity,
            //     RESIDUAL_STAKE_TOKEN,
            //     _shares[i].allocation,
            //     ""
            // );
            //usageTerms.addAdmin(_shares[i].entity);
        }
    }

    function isBalancedOwnership(ParadimeTokens.Shares[] memory _shares) private returns (bool) {
        uint256 counter = 0;
        for(uint256 i = 0; i <= _shares.length; i++) {
            counter += _shares[i].allocation;
        }

        return counter == 100;
    }

    modifier isValidCreatorStakes(ParadimeTokens.Shares[] memory _owners,
        ParadimeTokens.Shares[] memory _residualOwners) {
        //TODO: Make sure stakes = 100 || 1000 || 10000
        require(isBalancedOwnership(_owners), "Unbalanced ownership stake, the total share amount must equal 100");
        require(isBalancedOwnership(_residualOwners), "Unbalanced residual ownership stake, the total share amount must equal 100");
        _;
    }

    modifier canMakeModifications() {
        require(isPaused && usageTerms.isAdmin[msg.sender], "Only token admins can perform this action");
        _;
    }

    //Minting Utility Tokens
    function mint(uint256 _tokenId ,uint256 _amount) public {
        _mint(
            msg.sender,
            _tokenId,
            _amount,
            ""
        );
    }

    function isTokenAdmin() public view returns (bool) {
        return usageTerms.isAdmin[msg.sender];
    }

    function canPublish() public view returns (bool) {
        return usageTerms.permissions[TokenConsumptionTerms.PUBLISH_ACTION];
    }

    function canExport() public view returns (bool) {
        return usageTerms.permissions[TokenConsumptionTerms.EXPORT_ACTION];
    }

    function canRemix() public view returns (bool) {
        return usageTerms.permissions[TokenConsumptionTerms.REMIX_ACTION];
    }

    function canSample() public view returns (bool) {
        return usageTerms.permissions[TokenConsumptionTerms.SAMPLE_ACTION];
    }

    function getRemixPublishRate() public view returns (uint) {
        return usageTerms.royalties[TokenConsumptionTerms.SAMPLE_ACTION];
    }

    function getSamplePublishRate() public view returns (uint) {
        return usageTerms.royalties[TokenConsumptionTerms.REMIX_ACTION];
    }

    function getResaleRoyalty() public view returns (uint) {
        return usageTerms.royalties[TokenConsumptionTerms.RESELL_ACTION];
    }  

    function hasOwnerStake() public view returns (bool) {
        return balanceOf(msg.sender, OWNERSHIP_STAKE_TOKEN) > 0;
    }
        
    function getOwnerStake(address _user) public view returns (uint256) {
        return balanceOf(_user, OWNERSHIP_STAKE_TOKEN);
    }

    function hasResidualOwnerStake() public view returns (bool) {
        return balanceOf(msg.sender, RESIDUAL_STAKE_TOKEN) > 0;
    }

    function getResidualOwnerStake(address _user) public view returns (uint256) {
        return balanceOf(_user, RESIDUAL_STAKE_TOKEN);
    }

    function isRebalanceTransfer(
        address to,
        address from,
        uint256 id,
        uint256 amount
    ) internal returns (bool, bool) {
        return (
            balanceOf(to, id) > 0, 
            (balanceOf(from, id) - amount) == 0
        );        
    } 

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override(ERC1155) {
        //New owner or removal of owner check
        (bool isNewOwner, bool isRemoveOwner) = isRebalanceTransfer(to, from, id, amount);
        super.safeTransferFrom(from, to, id, amount, data);
        //Create Owners Index if new owner is added and/or owners shares are transfered to another existing owner.
        if (isNewOwner) {
            if (id == OWNERSHIP_STAKE_TOKEN) {
                stakeHolders.addOwner(to);
            }   
            if (id == RESIDUAL_STAKE_TOKEN) {
                stakeHolders.addResidualOwner(to);
            }
        }
        if (isRemoveOwner) {
            if (id == OWNERSHIP_STAKE_TOKEN) {
                stakeHolders.removeOwner(to);
            }   
            if (id == RESIDUAL_STAKE_TOKEN) {
                stakeHolders.removeResidualOwner(to);
            }
        }
    }

    function payOwners() public payable returns (bool) {
        //Create Transaction Id
        paymentTransactionIndex.increment();
        uint256 currentUserBalance = 0;
        uint256 userPaymentAmount = 0;
        for(uint256 i = 0; i <= stakeHolders.owners.length; i++) {
            currentUserBalance = balanceOf(stakeHolders.owners[i], OWNERSHIP_STAKE_TOKEN);
            if (currentUserBalance > 0) {
                userPaymentAmount = (msg.value * currentUserBalance / 100);
                (bool _paradimePaymentSuccess, ) = address(stakeHolders.owners[i]).call{value : userPaymentAmount}("");
                if (_paradimePaymentSuccess) {
                    //TODO: STORE BALANCE IF PAYMENT NOT SUCCESSFUL.
                    emit PaymentIssued(
                        paymentTransactionIndex.current(),
                        OWNERSHIP_STAKE_TOKEN,
                        userPaymentAmount,
                        stakeHolders.owners[i],
                        currentUserBalance
                    );
                } else {
                    revert();
                }
            }
        }
        return true;
    }

    function payResidualOwners() public payable {
        //Create Transaction Id
        paymentTransactionIndex.increment();
        uint256 currentUserBalance = 0;
        uint256 userPaymentAmount = 0;
        for(uint256 i = 0; i <= stakeHolders.residualOwners.length; i++) {
            currentUserBalance = balanceOf(stakeHolders.residualOwners[i], OWNERSHIP_STAKE_TOKEN);
            if (currentUserBalance > 0) {
                userPaymentAmount = (msg.value * currentUserBalance / 100);
                (bool _paradimePaymentSuccess, ) = payable(address(stakeHolders.residualOwners[i])).call{value : userPaymentAmount}("");
                if (_paradimePaymentSuccess) {
                    //TODO: STORE BALANCE IF PAYMENT NOT SUCCESSFUL.
                    emit PaymentIssued(
                        paymentTransactionIndex.current(),
                        RESIDUAL_STAKE_TOKEN,
                        userPaymentAmount,
                        stakeHolders.residualOwners[i],
                        currentUserBalance
                    );
                } else {
                    revert();
                }
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

library ParadimeTokens {
    struct TokenDefinition {
        address owner;
        bytes32 tokenId;
        ListingDetails listing;        
        uint256 totalMinted;
        bool isPaused;
    }

    struct Shares {
        address payable entity;
        uint16 allocation;
    }

    struct ListingDetails {
        uint256 price;
        uint32 launchDate;
        uint256 supply;
    }

    function canMint(TokenDefinition storage self, uint256 amount) external view returns (bool) {
        return self.listing.launchDate >= block.timestamp && self.listing.supply >= amount;
    }

    function mintAmount(TokenDefinition storage self, uint256 amount) external {
        require((self.totalMinted + amount) <=  self.listing.supply, "Invalid amount");
        self.totalMinted += amount;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

library BundleDefinition {
    struct Bundle {
        uint256[] tokens;
        uint256 price;
        bool isActive;
        uint256 launchDate;
    }


    function getSize(Bundle memory self) external returns (uint256) {
        return self.tokens.length;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

library OwnerStakes {

    struct OwnerEntites {
        address[] owners;
        address[] residualOwners;
    }

    function addOwner(OwnerEntites storage self, address _owner) external {
        self.owners.push(_owner);
    }

    function addResidualOwner(OwnerEntites storage self, address _owner) external {
        self.residualOwners.push(_owner);
    }

    function removeOwner(OwnerEntites storage self, address oldOwner) external {
        uint256 _elementIndex = 0;
        bool _foundMatch = false;
        for(uint256 i = 0; i <= self.owners.length; i++) {
            if (self.owners[i] == oldOwner) {
                _foundMatch = true;
                _elementIndex = i;
                break;
            }
        }

        if (_foundMatch) {
            for (uint i = _elementIndex; i < self.owners.length - 1; i++) {
                self.owners[i] = self.owners[i + 1];
            }
            self.owners.pop();
        }
    }

    function removeResidualOwner(OwnerEntites storage self, address oldOwner) external {
        uint256 _elementIndex = 0;
        bool _foundMatch = false;
        for(uint256 i = 0; i <= self.residualOwners.length; i++) {
            if (self.residualOwners[i] == oldOwner) {
                _foundMatch = true;
                _elementIndex = i;
                break;
            }
        }

        if (_foundMatch) {
            for (uint i = _elementIndex; i < self.residualOwners.length - 1; i++) {
                self.residualOwners[i] = self.residualOwners[i + 1];
            }
            self.residualOwners.pop();
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

library TokenConsumptionTerms {
    bytes32 internal constant PUBLISH_ACTION = keccak256("PUBLISH");
    bytes32 internal constant EXPORT_ACTION = keccak256("EXPORT");
    bytes32 internal constant SAMPLE_ACTION = keccak256("SAMPLE");
    bytes32 internal constant REMIX_ACTION = keccak256("REMIX");
    bytes32 internal constant RESELL_ACTION = keccak256("RESELL");
    //Permissions
    struct PermissionsAndRoyalties {
        mapping (address => bool) isAdmin;
        mapping (bytes32 => bool) permissions;
        mapping (bytes32 => bool) customPermissions;
        mapping (uint256 => mapping(bytes32 => bool)) permissionsOverrides;
        mapping (bytes32 => uint) royalties;
    }
    /*

    */
    modifier isAdmin(PermissionsAndRoyalties storage self) {
        require(self.isAdmin[msg.sender], "Only Admins can make modifications to a token");
        _;
    }
    /**
        Request Approval First
     */
    function addAdmin(PermissionsAndRoyalties storage self, address _newAdmin) isAdmin(self) external {
        self.isAdmin[_newAdmin] = true;
    }
    /**
        Request Approval First
     */
    function removeAdmin(PermissionsAndRoyalties storage self, address _newAdmin) isAdmin(self) external {
        self.isAdmin[_newAdmin] = false;
    }

    function isStandardPermission(PermissionsAndRoyalties storage self, bytes32 _permission) external returns (bool) {
        if (_permission == PUBLISH_ACTION || _permission == EXPORT_ACTION || _permission == SAMPLE_ACTION || _permission == REMIX_ACTION) return true;
        return false;
    }
    /**
        Request Approval First
     */
    function addUtilityPermission(PermissionsAndRoyalties storage self, uint256 _utilityToken, bytes32 _permission, bool _value) isAdmin(self) external {
        //require(self.isAdmin(msg.sender), "Only Admins can make modifications to a token");
        self.permissionsOverrides[_utilityToken][_permission] = _value;
    }

    function hasPermission(PermissionsAndRoyalties storage self, bytes32 _permission) external returns (bool) {
        return self.permissions[_permission];
    }

    // function hasPermission(PermissionsAndRoyalties storage self, uint256 utilityToken, bytes32 _permission) external returns (bool) {
    //     return self.permissions[_permission] || self.permissionsOverrides[utilityToken][_permission];
    // }

    function getActionFee(PermissionsAndRoyalties storage self, bytes32 permission) external returns (uint256) {
        return self.royalties[permission];
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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