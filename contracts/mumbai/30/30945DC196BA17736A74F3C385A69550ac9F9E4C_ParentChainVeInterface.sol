// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

contract ParentChainVeInterface {
    struct Point {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint256 ts;
        uint256 blk; // block
    }

    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    enum DepositType {
        DEPOSIT_FOR_TYPE,
        CREATE_LOCK_TYPE,
        INCREASE_LOCK_AMOUNT,
        INCREASE_UNLOCK_TIME,
        MERGE_TYPE,
        SPLIT_TYPE
    }

    uint256 internal constant WEEK = 1 weeks;
    uint256 internal constant MAXTIME = 4 * 52 * WEEK;
    int128 internal constant iMAXTIME = int128(uint128(4 * 52 * WEEK));
    uint256 internal constant MULTIPLIER = 1 ether;

    string public constant name = "veSOLID";
    string public constant symbol = "veSOLID";
    string public constant version = "1.0.0";
    uint8 public constant decimals = 18.0;

    /// @dev ERC165 interface ID of ERC165
    bytes4 internal constant ERC165_INTERFACE_ID = 0x01ffc9a7;

    /// @dev ERC165 interface ID of ERC721
    bytes4 internal constant ERC721_INTERFACE_ID = 0x80ac58cd;

    /// @dev ERC165 interface ID of ERC721Metadata
    bytes4 internal constant ERC721_METADATA_INTERFACE_ID = 0x5b5e139f;

    /// @dev reentrancy guard
    uint8 internal constant _not_entered = 1;
    uint8 internal constant _entered = 2;

    /**
     * @dev storage slots start here
     */
    address public token;
    uint256 public supply;
    mapping(uint256 => LockedBalance) public locked;

    mapping(uint256 => uint256) public ownership_change;

    uint256 public epoch;
    mapping(uint256 => Point) public point_history; // epoch -> unsigned point
    mapping(uint256 => Point[1000000000]) public user_point_history; // user -> Point[user_epoch]

    mapping(uint256 => uint256) public user_point_epoch;
    mapping(uint256 => int128) public slope_changes; // time -> signed slope change

    mapping(uint256 => uint256) public attachments;
    address public voter;

    /// @dev Current count of token
    uint256 internal tokenId;

    /// @dev Mapping from NFT ID to the address that owns it.
    mapping(uint256 => address) internal idToOwner;

    /// @dev Mapping from NFT ID to approved address.
    mapping(uint256 => address) internal idToApprovals;

    /// @dev Mapping from NFT ID to delegated address.
    mapping(uint256 => address) internal idToDelegates;

    /// @dev Mapping from owner address to count of his tokens.
    mapping(address => uint256) internal ownerToNFTokenCount;

    /// @dev Mapping from owner address to mapping of index to tokenIds
    mapping(address => mapping(uint256 => uint256))
        internal ownerToNFTokenIdList;

    /// @dev Mapping from NFT ID to index of owner
    mapping(uint256 => uint256) internal tokenToOwnerIndex;

    /// @dev Mapping from owner address to mapping of operator addresses.
    mapping(address => mapping(address => bool)) internal ownerToOperators;

    /// @dev Mapping from owner address to mapping of delegator addresses.
    mapping(address => mapping(address => bool)) internal ownerToDelegators;

    /// @dev Mapping of interface id to bool about whether or not it's supported
    mapping(bytes4 => bool) internal supportedInterfaces;

    /// @dev reentrancy guard
    uint8 internal _entered_state = 1;

    /// @dev Records last owner if withdrawn
    mapping(uint256 => address) ownerWhenWithdrawn;

    /// @dev Records tokenId if merged
    mapping(uint256 => uint256) public mergedInto;

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    event Delegate(
        address indexed owner,
        address indexed delegate,
        uint256 indexed tokenId
    );
    event DelegateForAll(
        address indexed owner,
        address indexed delegate,
        bool approved
    );
    event Deposit(
        address indexed provider,
        uint256 tokenId,
        uint256 value,
        uint256 indexed locktime,
        uint8 deposit_type,
        uint256 ts
    );
    event Supply(uint256 prevSupply, uint256 supply);
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Withdraw(
        address indexed provider,
        uint256 tokenId,
        uint256 value,
        uint256 ts
    );

    function approve(address _approved, uint256 _tokenId) external {}

    function attach(uint256 _tokenId) external {}

    function balanceOf(address _owner) external view returns (uint256) {}

    function balanceOfAtNFT(uint256 _tokenId, uint256 _block)
        external
        view
        returns (uint256)
    {}

    function balanceOfNFT(uint256 _tokenId) external view returns (uint256) {}

    function balanceOfNFTAt(uint256 _tokenId, uint256 _t)
        external
        view
        returns (uint256)
    {}

    function batchMergedInto(uint256 _tokenId, uint256 maxRuns) external {}

    function block_number() external view returns (uint256) {}

    function checkpoint() external {}

    function create_lock(uint256 _value, uint256 _lock_duration)
        external
        returns (uint256)
    {}

    function create_lock_for(
        uint256 _value,
        uint256 _lock_duration,
        address _to
    ) external returns (uint256) {}

    function delegate(address _delegate, uint256 _tokenId) external {}

    function deposit_for(uint256 _tokenId, uint256 _value) external {}

    function detach(uint256 _tokenId) external {}

    function getApproved(uint256 _tokenId) external view returns (address) {}

    function getDelegate(uint256 _tokenId) external view returns (address) {}

    function get_last_user_slope(uint256 _tokenId)
        external
        view
        returns (int128)
    {}

    function governanceAddress()
        external
        view
        returns (address _governanceAddress)
    {}

    function increase_amount(uint256 _tokenId, uint256 _value) external {}

    function increase_unlock_time(uint256 _tokenId, uint256 _lock_duration)
        external
    {}

    function initialize(address token_addr) external {}

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool)
    {}

    function isApprovedOrOwner(address _spender, uint256 _tokenId)
        external
        view
        returns (bool)
    {}

    function isDelegateForAll(address _owner, address _operator)
        external
        view
        returns (bool)
    {}

    function isDelegateOrOwner(address _voter, uint256 _tokenId)
        external
        view
        returns (bool)
    {}

    function locked__end(uint256 _tokenId) external view returns (uint256) {}

    function merge(uint256 _from, uint256 _to) external {}

    function ownerOf(uint256 _tokenId) external view returns (address) {}

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {}

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) external {}

    function setApprovalForAll(address _operator, bool _approved) external {}

    function setDelegateForAll(address _delegate, bool _status) external {}

    function setVoter(address _voter) external {}

    function split(uint256 _from, uint256 _amount) external returns (uint256) {}

    function supportsInterface(bytes4 _interfaceID)
        external
        view
        returns (bool)
    {}

    function tokenOfOwnerByIndex(address _owner, uint256 _tokenIndex)
        external
        view
        returns (uint256)
    {}

    function tokenURI(uint256 _tokenId) external view returns (string memory) {}

    function totalSupply() external view returns (uint256) {}

    function totalSupplyAt(uint256 _block) external view returns (uint256) {}

    function totalSupplyAtT(uint256 t) external view returns (uint256) {}

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {}

    function user_point_history__ts(uint256 _tokenId, uint256 _idx)
        external
        view
        returns (uint256)
    {}

    function voted(uint256 _tokenId) external view returns (bool isVoted) {}

    function withdraw(uint256 _tokenId) external {}
}