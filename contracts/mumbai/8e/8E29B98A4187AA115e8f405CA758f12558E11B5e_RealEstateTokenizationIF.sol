/**
 *Submitted for verification at polygonscan.com on 2022-12-05
*/

/*
  ############################################
  .__ .___.__..     .  ..__..___..___..___.__   
  [__)[__ [__]|     |\/|[__]  |    |  [__ [__)  
  |  \[___|  ||___  |  ||  |  |    |  [___|  \  

  ############################################

    Real Matter Technology Limited (c) 2022
        Chip-level Blockchain Identity
        Real-world Asset Tokenization
             Smart Legal Contract

              www.realmatter.io
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// File: Codes/Remix/Real/IRealASSETTokenRedeem.sol



/*
  ############################################
  .__ .___.__..     .  ..__..___..___..___.__   
  [__)[__ [__]|     |\/|[__]  |    |  [__ [__)  
  |  \[___|  ||___  |  ||  |  |    |  [___|  \  

  ############################################

    Real Matter Technology Limited (c) 2022
        Chip-level Blockchain Identity
        Real-world Asset Tokenization
            Smart Legal Contract

             www.realmatter.io

            Interface Functions

*/

pragma solidity ^0.8.17;

//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


//
// ERC20 Tokens for Redemption
//

interface IRealASSETRedeem is IERC20Metadata {

    //
    // transfer ERC20 Redeem token
    // via Interface Contract
    // only from token owner of this msg.sender or from approved spender with enough allowance
    //
    function transferRedeemviaInterface(
        address from,
        address to,
        uint256 amount) 
        external;
}


//
// ERC1155 NFT for Tokenization with Redemption
//
interface IRealASSETToken is IERC1155, IRealASSETRedeem {

    // set URI to NFT metadata of every NFT tokens 
    // only owner of this contract or the interface   
    function setAssetUri(
        uint256 tokenId, 
        string memory uri) 
        external;    
    // read back the URI by Token ID
    // override
    function uri(
        uint256 tokenId) 
        external view returns (string memory);


    // mint additional NFT token for more asset edition (new tokenID), or
    // mint more NFT token in the same supply for the existing asset edition (existing tokekID)
    // if token ID already exists > mint more NFT and increase the total supply (e.g. divident)
    // if token ID is new > mint the new NFT with the said total supply (e.g. new edition for sales)
    // not come with ERC20 Redeem Tokens
    // only owner of this contract or the interface
    function mintAssetEdition(
        address _editionOwner,
        uint256 _editionId,
        uint256 _editionSupply,
        string memory _editionURI)
        //string memory editionName) 
        external;


    //
    // safe transfer NFT token 
    // via Interface Contract
    // only from token owner of this msg.sender or from approved spender for all
    //
    function transferAssetviaInterface(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data) 
        external;                    // ERC1155.saferTransferFrom


    // safe transfer NFT token 
    // on Royalty Fee to this Real Contract
    // payable from msg.sender
    function transferAssetonRoyalty(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data) 
        external payable;            // ERC1155.saferTransferFrom
    
  
    //
    // view functions for interface contract
    //
    function readAssetDidCredential()
        external view returns (string memory);
    function readAssetTokenName()
        external view returns (string memory); 
    function readAssetTotalSupply()
        external view returns (uint256);
    function readAssetIdNext()
        external view returns (uint256);
    function readAssetTokenId()
        external view returns (uint256);


    /////////////////////////////////////////////////////////////////////////////////////////

    // write credential into blockchain event ledger
    // only owner of this contract or the interface
    function writeEventCredential(
        address writer,
        string memory text)
        external;


    //
    // Recovery Key to recover the contract ownership
    // with a new owner
    //
    function statusRecoveryKey()
        external view returns(bool);


    //
    // Interface address to this contract
    //
    function statusInterface()
        external view returns(bool);

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() 
        external view virtual returns (address);

}



// File: Codes/Remix/Real/RealEstateTokenizationIF.sol



/*
  ############################################
  .__ .___.__..     .  ..__..___..___..___.__   
  [__)[__ [__]|     |\/|[__]  |    |  [__ [__)  
  |  \[___|  ||___  |  ||  |  |    |  [___|  \  

  ############################################

    Real Matter Technology Limited (c) 2022
        Chip-level Blockchain Identity
        Real-world Asset Tokenization
             Smart Legal Contract

              www.realmatter.io

           Smart Contract Interface
           Real Estate Tokenization
          Asset Tokens in ERC1155 NFT
            Redeem Tokens in ERC20
*/

pragma solidity ^0.8.17;




//
// Interface Contract to access the real contract
//
contract RealEstateTokenizationIF{

    // read interface contract owner on
    // state valuable
    address public interfaceOwner;

    // read interacting Real Contract on
    // state valuable
    IRealASSETToken public realContract;
    bool public statusRecoveryKey = false;
    bool public statusContract = false;
    
    // read about this
    // state valuables
    string public aboutContract;
    string public aboutThisAsset;
    string public aboutThisTokenization;
    string public marketplaceDefault;

    // constructor of this Interface
    // is always the default owner transferrable
    constructor() public {
      interfaceOwner = msg.sender;
    }
    modifier onlyInterfaceOwner() {
        _checkInterfaceOwner();
        _;
    }
    function _checkInterfaceOwner() 
        internal view {

        require(interfaceOwner == msg.sender, "Ownable: caller is not the Interface Owner");
    }
    function adminNewInterfaceOwnership(
      address newInterfaceOwner)
      public onlyInterfaceOwner returns (string memory){

      interfaceOwner = newInterfaceOwner;
      return string ("Interface Contract: ownership transferred");
    }      


    // start or re-start the interface to the Real Contract
    function adminStartRealContract(
      address payable _realContractAddr)
      public onlyInterfaceOwner returns (string memory, address){
        
      require (_realContractAddr != address(0), "Real Contract: cannot be zero address");
      realContract = IRealASSETToken(_realContractAddr);
      statusRecoveryKey = realContract.statusRecoveryKey();
      statusContract = realContract.statusInterface();

      string memory realText = "Real Contract: Started by ";
      return (realText, _realContractAddr);
    }

    /////////////////////////////////////////////////////////////////////////////////////

    //
    // read Real Contract about values of asset tokenization
    // 
    function readEstateCredential()
      public view returns (string memory, string memory, string memory){

      string memory realText0 = "Real Estate Token Credential : [1] DID Credential , [2] Token Name";
      string memory realText1 = realContract.readAssetDidCredential();
      string memory realText2 = realContract.readAssetTokenName();
      return (realText0, realText1, realText2);
    }
    function readEstateToken()
      public view returns (string memory, uint256, uint256, uint256){

      string memory realText0 = "Real Estate Token Information : [1] TokenID , [2] Edition number , [3] Total supply";
      uint256 realNumber1 = realContract.readAssetTokenId();
      uint256 realNumber2 = realContract.readAssetIdNext() - 1;
      uint256 realNumber3 = realContract.readAssetTotalSupply();
      return (realText0, realNumber1, realNumber2, realNumber3);
    }
    // read Real Contract about values of redeem token information
    function readRedeemToken()
      public view returns (string memory, string memory, uint256, uint256){

      string memory realText0 = "Redeem Token information : [1] Symbol , [2] Decimals , [3] Redeem Supply";
      string memory realText1 = realContract.symbol();
      uint256 realNumber2 = realContract.decimals();
      uint256 realNumber3 = realContract.totalSupply();  
      return (realText0, realText1, realNumber2, realNumber3);
    }
    // read Real Contract about the pool information
    function readPoolContract()
      public view returns (string memory, address, address){

      string memory realText0 = "Real Contract Pool Address : [1] Owner, [2] Contract";
      address realContractOwner = realContract.owner();
      return (realText0, realContractOwner, address(realContract));
    }
    // read token holder's balance
    function readBalanceOf(
      address _tokenHolder)
      public view returns (string memory, uint256, uint256){

      string memory realText0 = "Real token [1] balance of this holder [Asset , Redeem]";
      uint256 realNumber1 = realContract.balanceOf(_tokenHolder, 1);   // ERC1155.balancOf
      uint256 realNumber2 = realContract.balanceOf(_tokenHolder);     // ERC20.balanceOf
      return (realText0, realNumber1, realNumber2);
    }
    function readBalanceOf(
      address _tokenHolder,
      uint256 _tokenId)
      public view returns (string memory, uint256, uint256, uint256){

      string memory realText0 = "Real token balance of this holder : [1] Token , [2] Asset , [3] Redeem]";
      uint256 realNumber2 = realContract.balanceOf(_tokenHolder, _tokenId);   // ERC1155.balancOf
      uint256 realNumber3 = realContract.balanceOf(_tokenHolder);     // ERC20.balanceOf
      return (realText0, _tokenId, realNumber2, realNumber3);
    }

    //
    // transfer Real Estate Tokens from msg.sender
    // back to the Real Contract owner only
    //
    function claimEstateTokenBack(
        //address from,
        address toContract,
        uint256 tokenId,
        uint256 amount,
        bytes memory remarkData) 
        public {

        // restricted to Real Contract owner only
        require(toContract == realContract.owner(), "Transferrable: recipient is not the Real Contract owner");
        address from = msg.sender;
 
        // firstly need msg.sender to execute 
        //   setApprovalForAll (this.address, TRUE)
        // for this interface contract on the real contract
        realContract.transferAssetviaInterface (from, toContract, tokenId, amount, remarkData);   // ERC1155.safeTransferFrom
        
        //require(ok, "Transferrable: failed");
    } 

    // transfer Redeem token from [email protected] 
    // back to the Real Contract owner only
    function claimRedeemBack(
        //address from,
        address toContract,
        uint256 amount) 
        public {

        // restricted to Real Contract owner only
        require(toContract == realContract.owner(), "Transferrable: recipient is not the Real Contract owner");
        address from = msg.sender;
        
        // firstly need msg.sender to execute 
        //   approval (this.address, amount)
        // for this interface contract on the real contract  to call transferFrom()
        realContract.transferRedeemviaInterface (from, toContract, amount);    // ERC20.transfer
        
        //require(ok, "Transferrable: failed");
    } 

    // transfer Divident/Redeem token to [email protected] 
    // from the Real Contract owner only
    function payDivident(
        address fromContract,
        //address to,
        uint256 amount) 
        public {

        // firstly need real contract owner to execute 
        //   approval (this.address, amount)
        // for this interface contract to call transferFrom()
        require(fromContract == realContract.owner(), "Transferrable: sender is not the Real Contract owner");
        address to = msg.sender;
        
        // firstly need msg.sender to execute 
        //   approval (this.address, amount)
        // for this interface contract on the real contract
        realContract.transferRedeemviaInterface (fromContract, to, amount);    // ERC20.transfer
        
        //require(ok, "Transferrable: failed");
    } 


    // mint & transfer Real Estate NFT token as Utility to msg.sender 
    // from the Real Contract owner
    // only NFT asset at assetId.ID_ASSET1
    function mintTransferEstateToken(
        uint256 amountUtility) 
        public {

        // restricted to Real Contract owner > msg.sender at assetId.ID_ASSET1 only
        //address _from = realContract.owner();
        address _to = msg.sender; 
        uint256 _tokenId = realContract.readAssetTokenId(); 
        string memory _uri = realContract.uri(_tokenId);

        // mint new NFT token
        realContract.mintAssetEdition(_to, _tokenId, amountUtility, _uri);      // ERC1155.mint
    } 

    // mint additional Estate Edition on top of the first NFT
    // auto tokenId
    function mintEstateEdition(
        address editionOwner,
        //uint256 editionId,
        string memory editionURI,
        uint256 editionSupply)
        public returns (string memory, uint256, uint256){

        uint256 _editionId = realContract.readAssetIdNext();

        require (_editionId != 1, "Next Token ID starts from 2");
        realContract.mintAssetEdition(editionOwner, _editionId, editionSupply, editionURI);

        string memory realText0 = "New Estate Edition minted [Token ID , Supply]";
        uint256 realNumber1 = _editionId;
        uint256 realNumber2 = editionSupply;
        return (realText0, realNumber1, realNumber2);
    }    

    //
    // write About
    // only owner of this interface contract
    //
    function adminWriteAboutContract(
      string memory _aboutContract)
      public onlyInterfaceOwner{
        aboutContract = _aboutContract;
    }
    function adminWriteAboutThisAsset(
      string memory _aboutThisAsset)
      public onlyInterfaceOwner{
        aboutThisAsset = _aboutThisAsset;
    }
    function adminWriteAboutThisTokenization(
      string memory _aboutThisTokenization)
      public onlyInterfaceOwner{
        aboutThisTokenization = _aboutThisTokenization;
    }
    function adminWriteMarketplaceDefault(
      string memory _marketplaceDefault)
      public onlyInterfaceOwner{
        marketplaceDefault = _marketplaceDefault;
    }

}