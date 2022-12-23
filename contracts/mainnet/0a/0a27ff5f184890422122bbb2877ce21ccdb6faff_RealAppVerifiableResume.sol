/**
 *Submitted for verification at polygonscan.com on 2022-12-23
*/

/*

===============================

 +-+-+-+-+-+-+ +-+-+-+-+-+-+-+
 |T|a|l|e|n|t| |C|o|n|n|e|c|t|
 +-+-+-+-+-+-+ +-+-+-+-+-+-+-+

===============================
  
Talent Connect Limited
            
## Verifiable Block Resume

www.talentconnect.com.hk
                
*/    
  
// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

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

// File: Contracts/20221222/IRealTOKENGeneration.sol



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

              Smart Contract 
           for ERC20 Redeem Token
           and Redeem Tokens Pool

*/

pragma solidity ^0.8.17;



//
// ERC20 Tokens for Redemption
// non payable
// un-renounced ownership
// enable recovery key
//
interface IRealTokenGeneration is IERC20, IERC20Metadata {   

    // mint extra ERC20 Token
    // add to the total supply with no limit
    // only owner of this contract
    function adminMintMoreToken(
        address toHolder, 
        uint256 moreSupply)
        external;


    // totalSupply() for Polygonscan to read and display 
    // the total supply of this contract
    //
    // keep ERC20.totalSupply() unchanged

    ////////////////////////////////////////////////////////////////////////////////////////////

    //
    // initial token transfer with Time Lock
    // only owner of this contract
    //
    function tokenGenerationTimeLock(
        address toHolder, 
        uint256 amount_decimal18,
        uint256 timeToLockInSeconds) 
        external returns (bool);


    //
    // override transfer() with time lock check
    //
    function transfer(
        address to, 
        uint256 amount_decimal18) 
        external returns (bool);
    // function transferFrom() is limited by Time Lock 
    // however, some MarketetPlace using this transferFrom() may apply their own timelock 
    // this method is the master time lock for all
    function transferFrom(
        address from,
        address to, 
        uint256 amount_decimal18) 
        external returns (bool);


    //
    // Admin functions
    // the time lock
    //
    function readCurrentBlockTime()
        external view returns (uint256);
    
    //
    // read holder's time lock
    //
    function readTimeLock(
        address holder)
        external view returns (uint256);
    function readTimeLockDelete(
        address holder)
        external returns (uint256);

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
        external view returns (address);


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


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

// File: Contracts/20221222/IRealCREDVerifiable721.sol



/*
  ############################################
  .__ .___.__..     .  ..__..___..___..___.__   
  [__)[__ [__]|     |\/|[__]  |    |  [__ [__)  
  |  \[___|  ||___  |  ||  |  |    |  [___|  \  

  ############################################

  Real Matter Technology Limited (c) 2022-23
        Chip-level Blockchain Identity
        Real-world Asset Tokenization
             Smart Legal Contract

              www.realmatter.io

               Smart Contract
            interface Functions
*/

pragma solidity ^0.8.17;




//
// Asset Verifiable Credential to this contract cwner
// which the owner's adddress points to an asset
// non-transferrable
//
interface IRealCredVerifiable721 is IERC721 {

    // mint additional NFT token for more asset appendix (new tokenID)
    // not come with ERC20 Redeem Tokens
    // only owner of this contract or the interface
    function mintAssetAppendix(
        address _editionOwner,
        uint256 _editionId,
        string memory _editionURI)
        external;
    function mintAssetAppendixBatch(
        address[] memory _editionOwner,
        uint256[] memory _editionId,
        string[] memory _editionURI)
        external;
    function adminAdjustTotalSupply(
        uint256 _newTotalSupply)
        external;

    // 
    // write and read W3C Credential state variable
    // only Owner (issuer) of this contract
    //
    function writeW3CCredential(
        string memory did,   
        string memory name,
        string memory subjectType,
        string memory issuer,
        string memory issueDate,
        string memory expiryDate,
        string memory verifyMethod,
        string memory proofMethod,
        string memory serviceEndpoint)
        external;
    function readW3CCredential(
        uint256 _vc)
        external returns (string memory);

    //
    // add Credential Subject 
    //
    function pushCredentialSubject(
        string memory _key, 
        string memory _value)
        external;
    function popCredentialSubject()
        external;
    function removeCredentialSubject(
        uint index)
        external;
    function lengthCredentialSubject()
        external;
    function readCredentialSubject(
        uint index) 
        external returns(string memory, string memory);


    /////////////////////////////////////////////////////////////////////////////////////////
    
    // set URI to NFT metadata of every NFT tokens 
    // only owner of this contract or the interface   
    function setAssetUri(
        uint256 tokenId, 
        string memory uri) 
        external;
    // read back the URI by Token ID
    // override
    //function uri(
    function tokenURI(
        uint256 tokenId) 
        external view returns (string memory);


    ////////////////////////////////////////////////////////////////////////////////////////////////

    //
    // view functions for interface contract
    //
    function readAssetDidCredential()
        external returns (string memory);
    function readAssetTokenName()
        external returns (string memory);

    ////////////////////////////////////////////////////////////////////////////////////////////////

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

    //
    // ERC721
    //
    function balanceOf(
        address owner) 
        external view returns (uint256);
    function name() 
        external view returns (string memory);
    function symbol() 
        external view returns (string memory);
    function ownerOf(
        uint256 tokenId) 
        external view returns (address);        
    function totalSupply()
        external view returns (uint256);
    function totalSupply(uint256 id)
        external view returns (uint256);

}
// File: Contracts/20221222/RealAPPVerifiableResume.sol



/*
  ############################################
  .__ .___.__..     .  ..__..___..___..___.__   
  [__)[__ [__]|     |\/|[__]  |    |  [__ [__)  
  |  \[___|  ||___  |  ||  |  |    |  [___|  \  

  ############################################
 
   Real Matter Technology Limited (c) 2022-23
        Chip-level Blockchain Identity
        Real-world Asset Tokenization
             Smart Legal Contract

              www.realmatter.io

           Smart Contract Interface App
             Verifiable Credential

        W3C Compliant Verificable Credential
              for Blockchain Resume
         (mint NFT and transfer to DID)
                   also with
           receivable Real Tokens
           stored in this contract


*/

pragma solidity ^0.8.17;





//
// Interface Contract to access the real contract
//
contract RealAppVerifiableResume is ERC721Holder{

    event SignatureText (address indexed writer, uint256 blockTime, uint256 tokenId, string text1, string text2);

    // ERC721 TokenID
    uint256 constant public ID_TALENTCOMPANY_CREDENTIAL = 0;     // Credential = 0
    uint256 constant public ID_RESUME_RECORD_STARTFROM = 1;        // Resume record ID start from 1
    

    // W3C Verifiable Credential struc
    struct StructW3CCredential {
        string did;                 
        string name;                
        string subjectType;        
        string issuer;              
        string issueDate;           
        string expiryDate;          
        string verifyMethod;        
        string proofMethod;        
        string servicePoint;     
    }
    StructW3CCredential public w3CResumeCollection;

    // W3C Verifiable Credential enum
    enum vc{
        did,                 // e.g. "did:resume:talentconnect:issuer#company"
        name,                // e.g. "Talent Connect | Verifiable Blockchain Resume | Issuer Company"
        subjectType,         // e.g. "Verifiable Credential , Blockchain Resume"
        issuer,              // e.g. "Real Matter virtualassets.vc"
        issueDate,           // e.g. "2022-12-22T00:00:01Z"
        expiryDate,          // e.g. "9999-99-99T99:99:99Z"
        verifyMethod,        // e.g. "EcdsaSecp256k1VerificationKey2019"
        proofMethod,         // e.g. "publicKey , 0218b43a3d6fde10c289fe527128624cd4a9bb9109dc591910050ba35d87fe4bbe"
        servicePoint         // e.g. "Real Matter virtualassets.id"
    }

    // read interface contract owner on
    // state valuable
    address public interfaceOwner;

    // read interacting Real Contract on
    // state valuable
    IRealCredVerifiable721 public realContract;
    bool public statusRecoveryKey = false;
    bool public statusContract = false;

    // hold one ERC20 reward token contract
    IRealTokenGeneration public exchangeToken;
    string public exchangeTokenURI;
    string public signatureEventURI;

    

    // read about this
    // state valuables
    string public about;
    string public aboutContract;
    string public aboutVerifiableResume;
    string public aboutExchangeToken;
    string public aboutMarketplace;

    // constructor of this Interface
    // is always the default owner transferrable
    constructor() {
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
        address _realContractAddr)
        public onlyInterfaceOwner returns (string memory, address){
            
        require (_realContractAddr != address(0), "Real Contract: cannot be zero address");
        realContract = IRealCredVerifiable721(_realContractAddr);
        statusRecoveryKey = realContract.statusRecoveryKey();
        statusContract = realContract.statusInterface();

        string memory realText = "Real Contract: Started by ";
        return (realText, _realContractAddr);
    }

    ////////////////////////////////////////////////////////////////////////////////////

    //
    // read Real Contract about values of asset tokenization
    // refresh the state variable
    //
    function refresh_W3C_ResumeCollection() 
        public {

        w3CResumeCollection.did = realContract.readW3CCredential(uint256(vc.did));
        w3CResumeCollection.name = realContract.readW3CCredential(uint256(vc.name));
        w3CResumeCollection.subjectType = realContract.readW3CCredential(uint256(vc.subjectType));
        w3CResumeCollection.issuer = realContract.readW3CCredential(uint256(vc.issuer));
        w3CResumeCollection.issueDate = realContract.readW3CCredential(uint256(vc.issueDate));
        w3CResumeCollection.expiryDate = realContract.readW3CCredential(uint256(vc.expiryDate));
        w3CResumeCollection.verifyMethod = realContract.readW3CCredential(uint256(vc.verifyMethod));
        w3CResumeCollection.proofMethod = realContract.readW3CCredential(uint256(vc.proofMethod));
        w3CResumeCollection.servicePoint = realContract.readW3CCredential(uint256(vc.servicePoint));
    }

    //
    // read URL and total supply of the credential and editions
    // ERC721 NFT supply of one token is always ONE
    //
    function read_NFT_ResumeRecord(
        uint256 resumeRecordId)
        public view returns (string memory, string memory){

        string memory realText0 = "NFT ResumeRecord [URI link]";
        //string memory realText1 = realContract.uri(resumeRecordId);      // ERC1155
        string memory realText1 = realContract.tokenURI(resumeRecordId);   // ERC721
        return (realText0, realText1);
    }
    function read_NFT_TalentCompanyCredential()
        public view returns (string memory, string memory){

        uint256 recordId = ID_TALENTCOMPANY_CREDENTIAL;
        string memory realText0 = "NFT TalentCompany Credential [URI link]";
        //string memory realText1 = realContract.uri(recordId);      // ERC1155
        string memory realText1 = realContract.tokenURI(recordId);   // ERC721
        return (realText0, realText1);
    }
    function read_NFT_Total_Resume_Record()
        public view returns (uint256) {

        return (realContract.totalSupply()-1);
    }    

    //
    // mint addtional NFT edition of the member card
    // ERC721 NFT supply of one token is always ONE    
    //
    function mint_NFT_New_ResumeRecord_ID(
        address _newResume,
        uint256 _recordId,
        string memory _resumeRecordURI)
        public onlyInterfaceOwner {
        
        realContract.mintAssetAppendix(
            _newResume,
            _recordId,
            _resumeRecordURI);
    }



    //
    // transfer ERC20 and ERC721
    //
    function adminTransferNFTFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory remarkData) 
        public {

        // firstly need msg.sender to execute 
        //   setApprovalForAll (this.address, TRUE)
        // for this interface contract on the real contract
        realContract.safeTransferFrom (from, to, tokenId, remarkData);   // ERC721.safeTransferFrom
        
        //require(ok, "Transferrable: failed");
    } 
  
    function adminTransferExchangeTokenFrom(
        address from,
        address to,
        uint256 amount_decimal18) 
        public {

        // firstly need msg.sender to execute 
        //   approval (this.address, amount)
        // for this interface contract on the real contract
        exchangeToken.transferFrom (from, to, amount_decimal18);    // ERC20.transferFrom
        
        //require(ok, "Transferrable: failed");
    }    
    function adminTransferRewardToken(
        //address from,
        address to,
        uint256 amount_decimal18) 
        public {

        // firstly need msg.sender to execute 
        //   approval (this.address, amount)
        // for this interface contract on the real contract
        exchangeToken.transfer (to, amount_decimal18);              // ERC20.transfer
        
        //require(ok, "Transferrable: failed");
    } 


    //
    // write About
    // only owner of this interface contract
    //
    function adminWriteAboutAll(
        string memory _aboutContract,
        string memory _aboutVerifiableResume,
        string memory _aboutExchangeToken,
        string memory _aboutMarketplace,
        string memory _about)
        public onlyInterfaceOwner{

        if (bytes(_aboutContract).length > 0)     
            aboutContract = _aboutContract;
        if (bytes(_aboutVerifiableResume).length > 0)     
            aboutVerifiableResume = _aboutVerifiableResume;
        if (bytes(_aboutExchangeToken).length > 0)     
            aboutExchangeToken = _aboutExchangeToken;
        if (bytes(_aboutMarketplace).length > 0)     
            aboutMarketplace = _aboutMarketplace;
        if (bytes(_about).length > 0)     
            about = _about;
        else
            about = "Verifiable Resume by Real Matter Technology (C) 2022-23";
    }


    function adminWriteExchangeToken20(
        address _exchangeTokenAddr,
        string memory _exchangeTokenURI)
        public onlyInterfaceOwner{

        exchangeToken = IRealTokenGeneration(_exchangeTokenAddr);        
        exchangeTokenURI = _exchangeTokenURI;
    }

    /////////////////////////////////////////////////////////////////////////////

    function emitSignature(
        address signer,
        uint256 signerResumeRecordId,
        string memory signatureText)
        public {

        require (signer == msg.sender || interfaceOwner == msg.sender, "App: signer is not the message sender");
        require (signer == realContract.ownerOf(signerResumeRecordId), "App: signer does not own the resume record");
        emit SignatureText(signer, block.timestamp, signerResumeRecordId, "This Verifiable Resume Record ID signed by", signatureText);
    }

    function emitIssuer(
        uint256 issuedResumeRecordId,
        string memory issuerText)
        public onlyInterfaceOwner{

        emit SignatureText(msg.sender, block.timestamp, issuedResumeRecordId, "This Verifiable Resume Record ID issued by", issuerText);
    }

    function adminEmitEvent(
        address _addr,
        uint256 _number,
        string memory _text1, 
        string memory _text2)
        public onlyInterfaceOwner{

        emit SignatureText(_addr, block.timestamp, _number, _text1, _text2);
    }
    

}