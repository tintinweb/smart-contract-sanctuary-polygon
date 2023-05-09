/**
 *Submitted for verification at polygonscan.com on 2023-05-08
*/

// SPDX-License-Identifier: MIXED

// Sources flattened with hardhat v2.14.0 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]

// License-Identifier: MIT
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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// License-Identifier: MIT
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


// File @openzeppelin/contracts/token/ERC20/[email protected]

// License-Identifier: MIT
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


// File contracts/multisig_test.sol

// License-Identifier: UNLICENSED
pragma solidity ^0.8.17;


//CHECK THIS
interface IERC20Receiver {
    function onERC20Receive(address from, address tokenAddress, uint256 amount) external returns (bool);
}

contract MultiSigWalletTest {

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        
        return this.onERC721Received.selector;
    }

    


    event ReceivedTokens(address from, address tokenAddress, uint256 amount);

    function onERC20Receive(address from,address tokenAddress, uint256 amount) external returns (bool) {
        emit ReceivedTokens(from, tokenAddress, amount);
        return true;
    }
    event Deposit(address indexed sender, uint amount, uint balance);
   
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value
    );

    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;
    uint public numTreshold;

    struct Transaction {
        address to;
        uint value;
        bool executed;
        uint numConfirmations;
        
        
    }
    //index per owner
    event ProposeNewOwner( address indexed owner, uint indexed ownerIndex, address indexed newOwner);
    event ConfirmNewOwner(address indexed owner, uint indexed ownerIndex);
    event ExecuteAddOwner(address indexed owner, uint indexed ownerIndex, address indexed newOwner);

    struct Ownership {
        address newOwner;
        bool addExecuted;
        uint numConfirmations;
    }

    event ProposeRemoveOwner(address indexed owner, uint indexed removeIndex, address indexed addressRemove);
    event ConfirmeRemoveOwner(address indexed owner, uint indexed removeIndex);
    event ExcuteRemoveOwner(address indexed owner, uint indexed removeIndex, address indexed addressRemove);


    struct Deleting {
        address addressRemove;
        bool removeExecuted;
        uint numConfirmations;

    }
    
    event ProposeNewTreshold(address indexed owner, uint indexed tresholdIndex, uint newNumTreshold);
    event ConfirmNewTreshold(address indexed owner, uint indexed tresholdIndex);
    event ExecuteNewTreshold(address indexed owner, uint indexed tresholdIndex);


    struct Treshold {
        uint newNumTreshold;
        bool tresholdExecuted;
        uint numConfirmations;
    }

    event ProposeChangeOwner(address indexed owner, uint indexed rescueIndex, address oldOwner, address indexed newOwner);
    event ConfirmeChangeOwner(address indexed owner, uint indexed rescueIndex);
    event ImAmHere(address indexed owner, uint indexed rescueIndex );
    event ExcuteChangeOwner(address indexed owner, uint indexed rescueIndex, address oldOWner, address indexed newOwner);
    

    struct Rescue {
        address oldOwner;
        address newOwner;
        bool rescueExecuted;
        uint numConfirmations;
        bool imHere;
        uint256 timeToUnLock;
        bool lock;
    }
    event ProposeApproval(address indexed owner, uint indexed approvalIndex, address indexed tokenId, uint value);
    event ConfirmeApproval(address indexed owner, uint indexed approvalIndex);
    event ExecuteApproval(address indexed owner, uint indexed approvalIndex, address indexed tokenId, uint value);

    // struct Approvation {
    //     address tokenAddress;
    //     uint value;
    //     bool approveExecuted;
    //     uint numConfirmations;
        
    // }
    event ProposeTokenTransaction(
        address indexed owner,
        uint indexed tokenIndex,
        address tokenAddress,
        address to,
        uint value
    );

    event ConfirmTokenTransaction(address indexed owner, uint indexed txIndex);
    event RevokeTokenConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTokenTransaction(address indexed owner, uint indexed txIndex);

     struct TokenTransaction {
        address tokenAddress;
        address to;
        uint value;
        bool tokenExecuted;
        uint numConfirmations;   
    }

     event ProposeNFTTransaction(
        address indexed owner,
        uint indexed NFTIndex,
        address NFTAddress,
        address to,
        uint value
    );

    event ConfirmNFTTransaction(address indexed owner, uint indexed txIndex);
    event RevokeNFTConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteNFTTransaction(address indexed owner, uint indexed txIndex);

     struct NFTTransaction {
        address NFTAddress;
        address to;
        uint NFTid;
        bool NFTExecuted;
        uint numConfirmations;   
    }


    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;
    mapping(uint => mapping(address => bool)) public IsAddNewOwner;
    mapping(uint => mapping(address => bool)) public isRemoveOwner;
    mapping(uint => mapping(address => bool)) public isTreshold;
    mapping(uint => mapping(address => bool)) public isRescue;
    //mapping(uint => mapping(address => bool)) public isApprove;
    mapping(uint => mapping(address => bool)) public isToken;
    mapping(uint => mapping(address => bool)) public isNFT;

    Transaction[] public transactions;
    Ownership[] public ownerships;
    Deleting[] public delet;
    Treshold[] public tresholds;
    Rescue[] public resc;
    //Approvation[] public approvals;
    TokenTransaction[] public tokens;
    NFTTransaction[] public nfts;
    


    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }
    // modifier approvalExists(uint _approvalIndex) {
    //     require(_approvalIndex < approvals.length, "approval does not exist" );
    //     _;
    // }
    modifier NFTTransactionExists(uint _NFTIndex) {
        require(_NFTIndex < nfts.length, "NFT transaction does not exist" );
        _;
    }
    modifier tokenTransactionExists(uint _tokenIndex) {
        require(_tokenIndex < tokens.length, "token transaction does not exist" );
        _;
    }
       modifier rescueExists(uint _rescueIndex) {
        require(_rescueIndex < resc.length, "rescue does not exist" );
        _;
    }
     modifier tresholdExists(uint _tresholdIndex) {
        require(_tresholdIndex < tresholds.length, "treshold does not exist" );
        _;
    }
    modifier ownerExists(uint _ownerIndex) {
        require(_ownerIndex < ownerships.length, "owner does not exist" );
        _;
    }
    modifier ownerRemoverExists(uint _removeIndex) {
        require(_removeIndex < delet.length, "removeOwner does not exist" );
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }
modifier notExecutedNFTTransaction(uint _NFTIndex) {
        require(!nfts[_NFTIndex].NFTExecuted, "nft transaction already executed");
        _;
    } 

    modifier notExecutedTokenTransaction(uint _tokenIndex) {
        require(!tokens[_tokenIndex].tokenExecuted, "token transaction already executed");
        _;
    } 
    // modifier notExecutedApproval(uint _approvalIndex) {
    //     require(!approvals[_approvalIndex].approveExecuted, "approval already executed");
    //     _;
    // } 
    modifier notExecutedRescue(uint _rescueIndex) {
        require(!resc[_rescueIndex].rescueExecuted, "rescue already executed");
        _;
    }   

    modifier notExecutedTreshold(uint _tresholdIndex) {
        require(!tresholds[_tresholdIndex].tresholdExecuted, "treshold already executed");
        _;
    }    
    modifier notExecutedAddOwner(uint _ownerIndex) {
        require(!ownerships[_ownerIndex].addExecuted, "add owner already executed");
        _;
    }

    modifier notExecutedRemoveOwner(uint _removeIndex) {
        require(!delet[_removeIndex].removeExecuted, "remove alrady executed");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }
modifier notConfirmedNFTTransaction(uint _NFTIndex) {
        require(!isNFT[_NFTIndex][msg.sender], "nft transaction already confirmed");
        _;
    }
     modifier notConfirmeTokenTransaction(uint _tokenIndex) {
        require(!isToken[_tokenIndex][msg.sender], "token transaction already confirmed");
        _;
    }
    // modifier notConfirmeApproval(uint _approvalIndex) {
    //     require(!isApprove[_approvalIndex][msg.sender], "approval already confirmed");
    //     _;
    // }
      modifier notConfirmedRescue(uint _rescueIndex) {
        require(!isRescue[_rescueIndex][msg.sender], "rescue already confirmed");
        _;
    }

      modifier notConfirmedTreshold(uint _tresholdIndex) {
        require(!isTreshold[_tresholdIndex][msg.sender], "treshold already confirmed");
        _;
    }

    modifier notConfirmedAddOwner(uint _ownerIndex) {
        require(!IsAddNewOwner[_ownerIndex][msg.sender], "add owner already confirmed");
        _;
    }

     modifier notConfirmedRemoveOwner(uint _removeIndex) {
        require(!isRemoveOwner[_removeIndex][msg.sender], "Remove owner already confirmed");
        _;
    }


    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    constructor(address[] memory _owners, uint _numConfirmationsRequired, uint _numTreshold) {
        require(_owners.length > 1, "at least 2 owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations number"
        );
        require(
            _numTreshold > 0 &&
                _numTreshold < _owners.length,
            "invalid number of required treshold confirmations number"
        );
        
        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            
            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
        numTreshold = _numTreshold;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(
        address _to,
        uint _value
        //data??
    ) public onlyOwner {
        uint _txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, _txIndex, _to, _value);
    }

    function confirmTransaction(
        uint _txIndex
    )
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(
        uint _txIndex
    ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "number confirmations too low"
        );

        transaction.executed = true;


        (bool success, ) = transaction.to.call{value: transaction.value}(
            ""
        );
    
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(
        uint _txIndex
    ) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

         
     function proposeNewOwner(address _newOwner) public onlyOwner {
            uint ownerIndex = ownerships.length;

        ownerships.push(
            Ownership({
                newOwner: _newOwner,
                addExecuted: false,
                numConfirmations: 0
            })
        );

        emit ProposeNewOwner(msg.sender, ownerIndex, _newOwner);
    }

       function confirmNewOwner(
        uint _ownerIndex
    )
        public
        onlyOwner
        ownerExists(_ownerIndex)
        notExecutedAddOwner(_ownerIndex)
        notConfirmedAddOwner(_ownerIndex)
    {
        Ownership storage ownership = ownerships[_ownerIndex];
        ownership.numConfirmations += 1;
        IsAddNewOwner[_ownerIndex][msg.sender] = true;

        emit ConfirmNewOwner(msg.sender, _ownerIndex);
    }
    
        function executeAddOwner(
        uint _ownerIndex
       
    ) public onlyOwner ownerExists(_ownerIndex) notExecutedAddOwner(_ownerIndex) {
        Ownership storage ownership = ownerships[_ownerIndex];

        require(
            ownership.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        ownership.addExecuted = true;
        isOwner[ownership.newOwner] = true;
        owners.push(ownership.newOwner);


        emit ExecuteAddOwner(msg.sender, _ownerIndex, ownership.newOwner);
    }

 function proposeRemoveOwner(address _addressRemove) public onlyOwner {
        uint _removeIndex = delet.length;
        delet.push(
            Deleting({
                addressRemove: _addressRemove,
                removeExecuted: false,
                numConfirmations: 0
            })
        );

        emit ProposeRemoveOwner(msg.sender, _removeIndex, _addressRemove);

    }
      function confirmeRemoveOwner(
        uint _removeIndex
    )
         public
        onlyOwner
        ownerRemoverExists(_removeIndex)
        notExecutedRemoveOwner(_removeIndex)
        notConfirmedRemoveOwner(_removeIndex)
    {
        Deleting storage deleting = delet[_removeIndex];
        deleting.numConfirmations += 1;
        isRemoveOwner[_removeIndex][msg.sender] = true;

        emit ConfirmeRemoveOwner(msg.sender, _removeIndex);
    }
 
function excuteRemoveOwner(
    uint _removeIndex
   ) public 
    onlyOwner 
    ownerRemoverExists(_removeIndex) 
    notExecutedRemoveOwner(_removeIndex) {
        Deleting storage deleting = delet[_removeIndex];
    
    require(isOwner[deleting.addressRemove], "owner not found");
    require(owners.length > 1, "cannot remove last owner");
    require(
            deleting.numConfirmations >= numTreshold,
            "number of confirmations too low"
        );

        deleting.removeExecuted = true;

           for (uint256 i = 0; i < owners.length; i++) {
        if (owners[i] == deleting.addressRemove) {
            // Rimuove il proprietario dall'array spostando tutti gli elementi successivi a sinistra
            for (uint256 j = i; j < owners.length - 1; j++) {
                owners[j] = owners[j+1];
            }
            owners.pop();
            break;
        }
       

    isOwner[deleting.addressRemove] = false;
    }

        emit ExcuteRemoveOwner(msg.sender, _removeIndex, deleting.addressRemove);
    }


     function proposeNewTreshold(uint _newNumTreshold) public onlyOwner {
            uint _tresholdIndex = tresholds.length;

            require(_newNumTreshold > 0 , "cannot be 0");
            require(_newNumTreshold < owners.length, "treshold minore degli owner ");

        tresholds.push(
            Treshold({
                newNumTreshold: _newNumTreshold,
                tresholdExecuted: false,
                numConfirmations: 0
            })
        );

        emit ProposeNewTreshold(msg.sender, _tresholdIndex, _newNumTreshold);
    }

       function confirmNewTreshold(
        uint _tresholdIndex
    )
        public
        onlyOwner
        tresholdExists(_tresholdIndex)
        notExecutedTreshold(_tresholdIndex)
        notConfirmedTreshold(_tresholdIndex)
    {
        Treshold storage treshold = tresholds[_tresholdIndex];
        treshold.numConfirmations += 1;
        isTreshold[_tresholdIndex][msg.sender] = true;

        emit ConfirmNewTreshold(msg.sender, _tresholdIndex);
    }
    
        function executeNewTreshold(
        uint _tresholdIndex
        // uint newNumTreshold
    ) public onlyOwner tresholdExists(_tresholdIndex) notExecutedTreshold(_tresholdIndex) {
        Treshold storage treshold = tresholds[_tresholdIndex];

        require(
            treshold.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        
        treshold.tresholdExecuted = true;
        numTreshold = treshold.newNumTreshold;

        
        emit ExecuteNewTreshold(msg.sender, _tresholdIndex);
    }


    function proposeChangeOwner(address _oldOwner, address _newOwner) public onlyOwner {
            uint _rescueIndex = resc.length;

           require(!isOwner[_newOwner] && _newOwner != address(0), "already owner or address 0");
           require(isOwner[_oldOwner], "the old owner is not  actually an owner");

        resc.push(
            Rescue({
                oldOwner: _oldOwner,
                newOwner: _newOwner,
                rescueExecuted: false,
                numConfirmations: 0,
                imHere: false,
                lock: true,
                timeToUnLock: block.timestamp + 2 minutes

            })
            
            
        );

        emit ProposeChangeOwner(msg.sender, _rescueIndex ,_oldOwner, _newOwner);
    }


       function confirmeChangeOwner(
        uint _rescueIndex
    )
        public
        onlyOwner
        rescueExists(_rescueIndex)
        notExecutedRescue(_rescueIndex)
        notConfirmedRescue(_rescueIndex)
    {
        Rescue storage rescue = resc[_rescueIndex];
        rescue.numConfirmations += 1;
        isRescue[_rescueIndex][msg.sender] = true;

        emit ConfirmeChangeOwner(msg.sender, _rescueIndex);
    }

       function imAmHere(uint _rescueIndex) public 
        onlyOwner
        //onlyNomited
        rescueExists(_rescueIndex)
        notExecutedRescue(_rescueIndex)
        {
        Rescue storage rescue = resc[_rescueIndex];
        rescue.imHere = true;
        isRescue[_rescueIndex][msg.sender] = true;

        emit ImAmHere(msg.sender, _rescueIndex);
        }
    
        function excuteChangeOwner(
        uint _rescueIndex
        
    ) public onlyOwner rescueExists(_rescueIndex) notExecutedRescue(_rescueIndex) {
        Rescue storage rescue = resc[_rescueIndex];

        require(
            rescue.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );
        require (rescue.imHere == false, "called ImHere function");
        
        if(block.timestamp >= rescue.timeToUnLock && rescue.lock) {
            rescue.lock = false;
        }

        require(rescue.lock == false, "tempo non ancora passato");
        

        

        rescue.rescueExecuted = true;

        for (uint256 i = 0; i < owners.length; i++) {
        if (owners[i] == rescue.oldOwner) {
            // Rimuove il proprietario dall'array spostando tutti gli elementi successivi a sinistra
            for (uint256 j = i; j < owners.length - 1; j++) {
                owners[j] = owners[j+1];
            }
            owners.pop();
            owners.push(rescue.newOwner);
            break;
        }
        isOwner[rescue.newOwner]= true;
        isOwner[rescue.oldOwner]=false;
        
        emit ExcuteChangeOwner(msg.sender, _rescueIndex, rescue.oldOwner, rescue.newOwner);
    }
}
// function proposeApproval(
//         address _tokenAddress,
//         uint _value
//         ) public onlyOwner {
//         uint _approvalIndex = approvals.length;

//         approvals.push(
//             Approvation({
//                 tokenAddress: _tokenAddress,
//                 value: _value,
//                 approveExecuted: false,
//                 numConfirmations: 0
//             })
//         );

//         emit ProposeApproval(msg.sender, _approvalIndex, _tokenAddress, _value);
//     }

//     function confirmeApproval(
//         uint _approvalIndex
//     )
//         public
//         onlyOwner
//         approvalExists(_approvalIndex)
//         notExecutedApproval(_approvalIndex)
//         notConfirmeApproval(_approvalIndex)
//     {
//         Approvation storage approvation = approvals[_approvalIndex];
//         approvation.numConfirmations += 1;
//         isApprove[_approvalIndex][msg.sender] = true;

//         emit ConfirmeApproval(msg.sender, _approvalIndex);
//     }

//     function executeApproval(
//         uint _approvalIndex,
//         address _tokenAddress,
//         uint value
//     ) public onlyOwner approvalExists(_approvalIndex) notExecutedApproval(_approvalIndex) {
//         Approvation storage approvation = approvals[_approvalIndex];

//         require(
//             approvation.numConfirmations >= numConfirmationsRequired,
//             "number confirmations too low"
//         );

//         approvation.approveExecuted = true;

//         emit ExecuteApproval(msg.sender, _approvalIndex, _tokenAddress, value);
//     }

    //tokenTransaction

     function proposeTokenTransaction(
        address _to,
         address _tokenAddress,
        uint _value
    ) public onlyOwner {
        uint _tokenindex = tokens.length;
        

        tokens.push(
            TokenTransaction({
                to: _to,
                tokenAddress: _tokenAddress,
                value: _value,
                tokenExecuted: false,
                numConfirmations: 0
            })
        );

        emit ProposeTokenTransaction(msg.sender, _tokenindex, _to,_tokenAddress, _value);
    }

    function confirmTokenTransaction(
        uint _tokenIndex
    )
        public
        onlyOwner
        tokenTransactionExists(_tokenIndex)
        notExecutedTokenTransaction(_tokenIndex)
        notConfirmeTokenTransaction(_tokenIndex)
    {
        TokenTransaction storage tokenTransaction = tokens[_tokenIndex];
        tokenTransaction.numConfirmations += 1;
        isToken[_tokenIndex][msg.sender] = true;

        emit ConfirmTokenTransaction(msg.sender, _tokenIndex);
    }

    function executeTokenTransaction(
        uint _tokenIndex
    ) public onlyOwner tokenTransactionExists(_tokenIndex) notExecutedTokenTransaction(_tokenIndex) {
        TokenTransaction storage tokenTransaction = tokens[_tokenIndex];

        require(
            tokenTransaction.numConfirmations >= numConfirmationsRequired,
            "number confirmations too low"
        );

        tokenTransaction.tokenExecuted = true;

        
        IERC20(tokenTransaction.tokenAddress).transfer(tokenTransaction.to, tokenTransaction.value);


        emit ExecuteTokenTransaction(msg.sender, _tokenIndex);
    }

    function revokeTokenConfirmation(
        uint _tokenIndex
    ) public onlyOwner tokenTransactionExists(_tokenIndex) notExecutedTokenTransaction(_tokenIndex) {
        TokenTransaction storage tokenTransaction = tokens[_tokenIndex];

        require(isToken[_tokenIndex][msg.sender], "token transaction not confirmed");

        tokenTransaction.numConfirmations -= 1;
        isToken[_tokenIndex][msg.sender] = false;

        emit RevokeTokenConfirmation(msg.sender, _tokenIndex);
    }

    function proposeNFTTransaction(
        address _to,
         address _NFTAddress,
        uint _NFTid
    ) public onlyOwner {
        uint _NFTindex = nfts.length;
        

        nfts.push(
            NFTTransaction({
                to: _to,
                NFTAddress: _NFTAddress,
                NFTid: _NFTid,
                NFTExecuted: false,
                numConfirmations: 0
            })
        );

        emit ProposeNFTTransaction(msg.sender, _NFTindex,_NFTAddress, _to,  _NFTid);
    }

    function confirmNFTTransaction(
        uint _NFTIndex
    )
        public
        onlyOwner
        NFTTransactionExists(_NFTIndex)
        notExecutedNFTTransaction(_NFTIndex)
        notConfirmedNFTTransaction(_NFTIndex)
    {
        NFTTransaction storage NFTtransaction = nfts[_NFTIndex];
        NFTtransaction.numConfirmations += 1;
        isNFT[_NFTIndex][msg.sender] = true;

        emit ConfirmTokenTransaction(msg.sender, _NFTIndex);
    }

    function executeNFTTransaction(
        uint _NFTIndex
    ) public onlyOwner NFTTransactionExists(_NFTIndex) notExecutedNFTTransaction(_NFTIndex) {
        NFTTransaction storage NFTtransaction = nfts[_NFTIndex];

        require(
            NFTtransaction.numConfirmations >= numConfirmationsRequired,
            "number confirmations too low"
        );

        NFTtransaction.NFTExecuted = true;

        
        IERC721(NFTtransaction.NFTAddress).safeTransferFrom(address(this), NFTtransaction.to, NFTtransaction.NFTid);


        emit ExecuteNFTTransaction(msg.sender, _NFTIndex);
    }

    function revokeNFTConfirmation(
        uint _NFTIndex
    ) public onlyOwner NFTTransactionExists(_NFTIndex) notExecutedTokenTransaction(_NFTIndex) {
        NFTTransaction storage NFTtransaction = nfts[_NFTIndex];

        require(isNFT[_NFTIndex][msg.sender], "NFT transaction not confirmed");

        NFTtransaction.numConfirmations -= 1;
        isNFT[_NFTIndex][msg.sender] = false;

        emit RevokeNFTConfirmation(msg.sender, _NFTIndex);
    }
    

    function getTimeToUnlock(uint _rescueIndex) public view returns (uint) {
        Rescue storage rescue = resc[_rescueIndex];
        return (rescue.timeToUnLock - block.timestamp); 
    }
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

        function getOwnershipsCount() public view returns (uint) {
        return ownerships.length;
    }
    function getDeletCount() public view returns (uint) {
        return delet.length;
    }
    function getTresholdsCount() public view returns (uint) {
        return tresholds.length;
    }
    function getRescCount() public view returns (uint) {
        return resc.length;
    }
    function getTokenTxCount() public view returns (uint) {
        return tokens.length;
    }
    function getTransaction(
        uint _txIndex
    )
        public
        view
        returns (
            address to,
            uint value,

            bool executed,
            uint numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            
            transaction.executed,
            transaction.numConfirmations
        );
    }
    function getOwnerships(
        uint _ownerIndex
    )
        public
        view
        returns (
            address newOwner,
        bool addExecuted,
        uint numConfirmations
        )
    {
        Ownership storage ownership = ownerships[_ownerIndex];

        return (
            ownership.newOwner,
            ownership.addExecuted,
            ownership.numConfirmations
        );
    }
    function getDelet(
        uint _removeIndex
    )
        public
        view
        returns (
            address addressRemove,
        bool removeExecuted,
        uint numConfirmations
        )
    {
        Deleting storage deleting = delet[_removeIndex];

        return (
            deleting.addressRemove,
            deleting.removeExecuted,
            deleting.numConfirmations
        );
    }
    function getTreshold(
        uint _tresholdIndex
    )
        public
        view
        returns (
           uint newNumTreshold,
        bool tresholdExecuted,
        uint numConfirmations
        )
    {
        Treshold storage treshold = tresholds[_tresholdIndex];

        return (
            treshold.newNumTreshold,
            treshold.tresholdExecuted,
            treshold.numConfirmations
        );
    }
    function getResc(
        uint _rescueIndex
    )
        public
        view
        returns (
           address oldOwner,
        address newOwner,
        bool rescueExecuted,
        uint numConfirmations,
        bool imHere,
        uint256 timeToUnLock,
        bool lock
        )
    {
        Rescue storage rescue = resc[_rescueIndex];

        return (
            rescue.oldOwner,
            rescue.newOwner,
            rescue.rescueExecuted,
            rescue.numConfirmations,
            rescue.imHere,
            rescue.timeToUnLock,
            rescue.lock
        );
    }
    function getTokenTx(
        uint _tokenTransactionIndex
    )
        public
        view
        returns (
         address tokenAddress,
        address to,
        uint value,
        bool tokenExecuted,
        uint numConfirmations
        )
    {
        TokenTransaction storage tokenTransaction = tokens[_tokenTransactionIndex];

        return (
         tokenTransaction.tokenAddress,
         tokenTransaction.to,
         tokenTransaction.value,
         tokenTransaction.tokenExecuted,
         tokenTransaction.numConfirmations 
        );
    }
}