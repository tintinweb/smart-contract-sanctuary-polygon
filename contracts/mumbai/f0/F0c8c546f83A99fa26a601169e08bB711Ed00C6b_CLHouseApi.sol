// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "ICLHouse.sol";

/// @title Some view funtions to interact with a CLHouse
/// @author Leonardo Urrego
contract CLHouseApi {

    /// @notice A funtion to verify the signer of a menssage
    /// @param _msghash Hash of the message
    /// @param _signature Signature of the message
    /// @return Signer address of the message
    function SignerOfMsg(
        bytes32  _msghash,
        bytes memory _signature
    )
        public
        pure
        returns( address )
    {
        require( _signature.length == 65, "Bad signature length" );

        bytes32 signR;
        bytes32 signS;
        uint8 signV;

        assembly {
            // first 32 bytes, after the length prefix
            signR := mload( add( _signature, 32 ) )
            // second 32 bytes
            signS := mload( add( _signature, 64 ) )
            // final byte (first byte of the next 32 bytes)
            signV := byte( 0, mload( add( _signature, 96 ) ) )
        }

        return ecrecover( _msghash, signV, signR, signS );
    }


    struct strInfoUser {
        address wallet;
        uint256 userID;
        string nickname;
        bool isManager;
    }

    /// @notice The list of all users address
    /// @param _houseAddr address of the CLH
    /// @return arrUsers array of user address
    function GetHouseUserList(
        address _houseAddr
    )
        external
        view
        returns(
            strInfoUser[] memory arrUsers
        )
    {
        ICLHouse daoCLH = ICLHouse( _houseAddr );

        uint256 numUsers = daoCLH.numUsers( );
        uint256 arrUsersLength = daoCLH.GetArrUsersLength();
        arrUsers = new strInfoUser[] ( numUsers );

        uint256 index = 0 ;

        for( uint256 uid = 1 ; uid < arrUsersLength ; uid++ ) {
            strInfoUser memory houseUser;

            houseUser.wallet = daoCLH.arrUsers( uid );

            (   houseUser.userID,
                houseUser.nickname,
                houseUser.isManager ) = daoCLH.mapUsers( houseUser.wallet );

            if( 0 != houseUser.userID ){
                arrUsers[ index ] = houseUser;
                index++;
            }
        }
    }


    /// @notice Retrieve the signer from Offchain Invitation signature
    /// @param _acceptance True for accept the invitation
    /// @param _nickname A nickname for the user
    /// @param _houseAddr address of the CLH
    /// @param _signature EIP712 Signature
    /// @return Wallet address of the signer
    function SignerOCInvit(
        bool _acceptance,
        string memory _nickname,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCINVIT_HASH__,
                _acceptance,
                keccak256( abi.encodePacked( _nickname ) )
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    /// @notice Retrieve the signer from Offchain Vote signature
    /// @param _propId ID of the proposal, based on `arrProposals`
    /// @param _support True for accept, false to reject
    /// @param _justification About your vote
    /// @param _houseAddr address of the CLH
    /// @param _signature EIP712 Signature
    /// @return Wallet address of the signer
    function SignerOCVote(
        uint _propId,
        bool _support,
        string memory _justification,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCVOTE_HASH__,
                _propId,
                _support,
                keccak256( abi.encodePacked( _justification ) )
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    /// @notice Retrieve the signer from Offchain BulkVote signature
    /// @param _propIds Array with ID of the proposal to votes
    /// @param _support is the Vote (True or False) for all proposals
    /// @param _justification Description of the vote
    /// @param _houseAddr address of the CLH
    /// @param _signature EIP712 Signature
    /// @return Wallet address of the signer
    function SignerOCBulkVote(
        uint256[] memory _propIds,
        bool _support,
        string memory _justification,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCBULKVOTE_HASH__,
                keccak256( abi.encodePacked( _propIds ) ),
                _support,
                keccak256( abi.encodePacked( _justification ) )
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    /// @notice Retrieve the signer from Offchain Invite User signature
    /// @param _walletAddr  Address of the new user
    /// @param _name Can be the nickname or other reference to the User
    /// @param _description A text for the proposal
    /// @param _isManager True if is for a manager
    /// @param _houseAddr address of the CLH
    /// @param _signature EIP712 Signature
    /// @return Wallet address of the signer
    function SignerOCInvitUser(
        address _walletAddr,
        string memory _name,
        string memory _description,
        bool _isManager,
        uint256 _delayTime,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCNEWUSER_HASH__,
                _walletAddr,
                keccak256( abi.encodePacked( _name ) ),
                keccak256( abi.encodePacked( _description ) ),
                _isManager,
                _delayTime
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    /// @notice Retrieve the signer from Offchain Remove User signature
    /// @param _walletAddr user Address to be removed
    /// @param _description About the proposal
    /// @param _houseAddr address of the CLH
    /// @param _signature EIP712 Signature
    /// @return Wallet address of the signer
    function SignerOCRemoveUser(
        address _walletAddr,
        string memory _description,
        uint256 _delayTime,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCDELUSER_HASH__,
                _walletAddr,
                keccak256( abi.encodePacked( _description ) ),
                _delayTime
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    /// @notice Retrieve the signer from Offchain request to join signature
    /// @param _name Nickname or other user identification
    /// @param _description About the request
    /// @param _houseAddr address of the CLH
    /// @param _signature EIP712 Signature
    /// @return Wallet address of the signer
    function SignerOCRequestToJoin(
        string memory _name,
        string memory _description,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCREQUEST_HASH__,
                keccak256( abi.encodePacked( _name ) ),
                keccak256( abi.encodePacked( _description ) )
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    /// @notice Retrieve the signer from Offchain New house signature
    /// @param _ownerName Nickname of the Owner
    /// @param _houseName Name of the CLH
    /// @param _housePrivate If is set to 1, the CLH is set to private
    /// @param _houseOpen If is set to 1, the CLH is set to open
    /// @param _govRuleMaxUsers Max users in the house
    /// @param _whiteListNFT Address of NFT Collection for users invitation
    /// @param _pxyCLF address of the CLF
    /// @param _signature EIP712 Signature
    /// @return Wallet address of the signer
    function SignerOCNewCLH(
        string memory _ownerName,
        string memory _houseName,
        bool _housePrivate,
        bool _houseOpen,
        uint256 _govRuleMaxUsers,
        address _whiteListNFT,
        address _pxyCLF,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _pxyCLF
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCNEWCLH_HASH__,
                keccak256( abi.encodePacked( _ownerName ) ),
                keccak256( abi.encodePacked( _houseName ) ),
                _housePrivate,
                _houseOpen,
                _govRuleMaxUsers,
                _whiteListNFT
                // keccak256( abi.encodePacked( _whiteListWallets ) )
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    /// @notice Retrieve the signer from Offchain New Lock signature
    /// @param _expirationDuration Expiration for lcok in seconds
    /// @param _keyPrice Price for each lock in wei
    /// @param _maxNumberOfKeys How many locks
    /// @param _lockName Lock Name
    /// @param _houseAddr address of the CLH
    /// @param _signature EIP712 Signature
    /// @return Wallet address of the signer
    function SignerOCNewLock(
        uint256 _expirationDuration,
        uint256 _keyPrice,
        uint256 _maxNumberOfKeys,
        string memory _lockName,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCNEWLOCK_HASH__,
                _expirationDuration,
                _keyPrice,
                _maxNumberOfKeys,
                keccak256( abi.encodePacked( _lockName ) )
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    /// @notice Retrieve the signer from Offchain Update CLH Name
    /// @param _houseName new CLH Name
    /// @param _houseAddr address of the CLH
    /// @param _signature EIP712 Signature
    /// @return Wallet address of the signer
    function SignerOCUpCLHName(
        string memory _houseName,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCUPCLH_NAME_HASH__,
                keccak256( abi.encodePacked( _houseName ) )
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    /// @notice Retrieve the signer from Offchain Update CLH Whitelist NFT
    /// @param _whiteListNFT New contract address of NFT
    /// @param _houseAddr address of the CLH
    /// @param _signature EIP712 Signature
    /// @return Wallet address of the signer
    function SignerOCUpCLHWLNFT(
        address _whiteListNFT,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCUPCLH_WLNFT_HASH__,
                _whiteListNFT
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    /// @notice Retrieve the signer from Offchain Update CLH govRuleMaxUsers
    /// @param _govRuleMaxUsers New value of MaxUsers
    /// @param _houseAddr address of the CLH
    /// @param _signature EIP712 Signature
    /// @return Wallet address of the signer
    function SignerOCUpCLHMaxUsers(
        uint256 _govRuleMaxUsers,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCUPCLH_GOVMAXUSERS_HASH__,
                _govRuleMaxUsers
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    /// @notice Retrieve the signer from Offchain Update CLH flag of housePrivate
    /// @param _housePrivate New value of housePrivate
    /// @param _houseAddr address of the CLH
    /// @param _signature EIP712 Signature
    /// @return Wallet address of the signer
    function SignerOCUpCLHPrivacy(
        bool _housePrivate,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCUPCLH_HOUSEPRIVATE_HASH__,
                _housePrivate
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }


    /// @notice Retrieve the signer from Offchain Update CLH flag of houseOpen
    /// @param _houseOpen New value of houseOpen
    /// @param _houseAddr address of the CLH
    /// @param _signature EIP712 Signature
    /// @return Wallet address of the signer
    function SignerOCUpCLHOpen(
        bool _houseOpen,
        address _houseAddr,
        bytes memory _signature
    ) 
        external view
        returns( address )
    {
        bytes32 hashEIP712Domain = keccak256(
            abi.encode(
                __STR_EIP712DOMAIN_HASH__,
                __CONTRACT_NAME_HASH__,
                __CONTRACT_VERSION_HASH__,
                block.chainid,
                _houseAddr
            )
        );

        bytes32 hashMsg = keccak256(
            abi.encode(
                __STR_OCUPCLH_HOUSEOPEN_HASH__,
                _houseOpen
            )
        );

        bytes32 singhash = keccak256( abi.encodePacked( "\x19\x01", hashEIP712Domain, hashMsg ) );

        return SignerOfMsg( singhash, _signature );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "CLTypes.sol";


interface ICLHouse {

    // View fuctions
    function numUsers() external view returns( uint256 );
    function arrUsers( uint256 ) external view returns( address );
    function mapUsers( address ) external view returns( uint256, string memory, bool );
    function arrProposals( uint256 ) external view returns( address, proposalType, string memory, uint16, uint8, uint8, bool, bool, uint256 );
    function arrDataPropUser( uint256 ) external view returns( address, string memory, bool );
    function arrDataPropGovRules( uint256 ) external view returns( uint256 );
    function GetArrUsersLength() external view returns( uint256 );
    function mapVotes( uint256,  address ) external view returns( bool, bool, string memory);


    // no-view functions
    function ExecProp(
        uint _propId
    )
        external 
        returns(
            bool status, 
            string memory message
        );

    function VoteProposal(
        uint _propId,
        bool _support,
        string memory _justification,
        bytes memory _signature
    )
        external;

    function PropInvitUser(
        address _walletAddr,
        string memory _name,
        string memory _description,
        bool _isManager,
        uint256 _delayTime,
        bytes memory _signature
    )
        external
        returns(
            uint propId
        );

    function PropRemoveUser(
        address _walletAddr,
        string memory _description,
        uint256 _delayTime,
        bytes memory _signature
    )
        external
        returns(
            uint propId
        );

    function PropRequestToJoin(
        string memory _name,
        string memory _description,
        address _signerWallet,
        bytes memory _signature
    )
        external
        returns(
            uint propId
        );

    function AcceptRejectInvitation(
        bool __acceptance,
        bytes memory _signature
    )
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/*
 * ### CLH constant Types ###
 */
string constant __CLHOUSE_VERSION__ = "0.2.1";

uint8 constant __UPGRADEABLE_CLH_VERSION__ = 1;
uint8 constant __UPGRADEABLE_CLF_VERSION__ = 1;

bytes32 constant __GOV_DICTATORSHIP__ = keccak256("__GOV_DICTATORSHIP__");
bytes32 constant __GOV_COMMITTEE__ = keccak256("__GOV_COMMITTEE__");
bytes32 constant __GOV_SIMPLE_MAJORITY__ = keccak256("__GOV_SIMPLE_MAJORITY__");
bytes32 constant __CONTRACT_NAME_HASH__ = keccak256("CLHouse");
bytes32 constant __CONTRACT_VERSION_HASH__ = keccak256(
    abi.encodePacked( __CLHOUSE_VERSION__ )
);
bytes32 constant __STR_EIP712DOMAIN_HASH__ = keccak256(
    abi.encodePacked(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    )
);
bytes32 constant __STR_OCINVIT_HASH__ = keccak256(
    abi.encodePacked(
        "strOCInvit(bool acceptance,string nickname)"
    )
);
bytes32 constant __STR_OCVOTE_HASH__ = keccak256(
    abi.encodePacked(
        "strOCVote(uint256 propId,bool support,string justification)"
    )
);
bytes32 constant __STR_OCBULKVOTE_HASH__ = keccak256(
    abi.encodePacked(
        "strOCBulkVote(uint256[] propIds,bool support,string justification)"
    )
);
bytes32 constant __STR_OCNEWUSER_HASH__ = keccak256(
    abi.encodePacked(
        "strOCNewUser(address walletAddr,string name,string description,bool isManager,uint256 delayTime)"
    )
);
bytes32 constant __STR_OCDELUSER_HASH__ = keccak256(
    abi.encodePacked(
        "strOCDelUser(address walletAddr,string description,uint256 delayTime)"
    )
);
bytes32 constant __STR_OCREQUEST_HASH__ = keccak256(
    abi.encodePacked(
        "strOCRequest(string name,string description)"
    )
);
bytes32 constant __STR_OCNEWCLH_HASH__ = keccak256(
    abi.encodePacked(
        "strOCNewCLH(string ownerName,string houseName,bool housePrivate,bool houseOpen,uint256 govRuleMaxUsers,address whiteListNFT)"
    )
);
bytes32 constant __STR_OCNEWLOCK_HASH__ = keccak256(
    abi.encodePacked(
        "strOCNewLock(uint256 expirationDuration,uint256 keyPrice,uint256 maxNumberOfKeys,string lockName)"
    )
);
bytes32 constant __STR_OCUPCLH_NAME_HASH__ = keccak256(
    abi.encodePacked(
        "strOCUpCLHName(string houseName)"
    )
);

bytes32 constant __STR_OCUPCLH_WLNFT_HASH__ = keccak256(
    abi.encodePacked(
        "strOCUpCLHWLNFT(address whiteListNFT)"
    )
);

bytes32 constant __STR_OCUPCLH_GOVMAXUSERS_HASH__ = keccak256(
    abi.encodePacked(
        "strOCUpCLHMaxUsers(uint256 govRuleMaxUsers)"
    )
);

bytes32 constant __STR_OCUPCLH_HOUSEPRIVATE_HASH__ = keccak256(
    abi.encodePacked(
        "strOCUpCLHPrivacy(bool housePrivate)"
    )
);

bytes32 constant __STR_OCUPCLH_HOUSEOPEN_HASH__ = keccak256(
    abi.encodePacked(
        "strOCUpCLHOpen(bool houseOpen)"
    )
);

/*
 * ### CLH enum Types ###
 */

enum userEvent{
    addUser,
    delUser,
    inviteUser,
    acceptInvitation,
    rejectInvitation,
    requestJoin
}

enum govRulesEvent{
    changeApprovPercentage,
    changeMaxUsers,
    changeMaxManagers
}

enum flagEvent{
    changeHousePrivate,
    changeHouseOpen
}

enum proposalEvent {
    addProposal,
    execProposal,
    rejectProposal
}

enum proposalType {
    newUser,
    removeUser,
    requestJoin,
    changeGovRules
}

/// @param CLLConstructorCLH Address of Logic Contract of CLH Constructor
/// @param pxyCLF Address of proxy Contract for CLFactory
/// @param pxyApiCLH Address of proxy Contract for CLHouseAPI
/// @param pxyNFTManager Address of proxy Contract for NFT Manager
/// @param pxyNFTMember Address of proxy Contract for NFT Member
/// @param pxyNFTInvitation Address of proxy Contract for NFT Invitation
/// @param whiteListNFT Address of proxy Contract for CLH Constructor
enum eCLC {
    CLLConstructorCLH,
    pxyCLF,
    pxyApiCLH,
    pxyNFTManager,
    pxyNFTMember,
    pxyNFTInvitation,
    whiteListNFT
}


/*
 * ### CLH struct Types ###
 */

struct strUser {
    uint256 userID;
    string nickname;
    bool isManager;
}

struct strProposal {
    address proponent;
    proposalType typeProposal;
    string description;
    uint256 propDataId;
    uint256 numVotes;
    uint256 againstVotes;
    bool executed;
    bool rejected;
    uint256 deadline;
}

struct strVote {
    bool voted;
    bool inSupport;
    string justification;
}

struct strDataUser {
    address walletAddr;
    string name;
    bool isManager;
}

struct strDataTxAssets {
    address to;
    uint256 amountOutCLV;
    address tokenOutCLV;
    address tokenInCLV;
}

struct strDataGovRules {
    uint256 newApprovPercentage;
}