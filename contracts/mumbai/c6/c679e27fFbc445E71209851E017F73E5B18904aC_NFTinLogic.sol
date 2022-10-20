// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {LensInteractions} from "./LensInteractions.sol";
import {DataTypes} from "./DataTypes.sol";
import {INFTinLogic} from "./INFTinLogic.sol";

contract NFTinLogic is LensInteractions, INFTinLogic{
    function onboardNewProfile(uint256 _profileId) external {
        profiles[msg.sender] = _profileId;
        emit profileOnboarded(msg.sender, _profileId);
    }

    function setPost(DataTypes.PostData calldata vars)
        external
        profileOwner(vars.profileId)
    {
        (bool success, uint256 _postId) = post(vars);
        require(success, "Transaction failed");
        postList[vars.profileId].push(_postId);
        emit posted(msg.sender, vars);
    }

    function setComment(DataTypes.CommentData calldata vars)
        external
        profileOwner(vars.profileId)
        pubExist(vars.profileIdPointed, vars.pubIdPointed)
    {
        (bool success, uint256 _commentId) = comment(vars);
        require(success, "transaction failed");

        Comments memory _comment;
        _comment.profileId = vars.profileId;
        _comment.profileIdPointed = vars.profileIdPointed;
        _comment.pubId = _commentId;
        _comment.pubIdPointed = vars.pubIdPointed;

        comments[vars.profileIdPointed][vars.pubIdPointed].push(_comment);
        addRating(vars.profileIdPointed);
        emit commented(msg.sender, vars);
    }

    function setMirror(DataTypes.MirrorData calldata vars)
        external
        profileOwner(vars.profileId)
        pubExist(vars.profileIdPointed, vars.pubIdPointed)
    {
        (bool success, uint256 _mirrorId) = mirror(vars);
        require(success, "transaction failed");

        Mirrors memory _mirror;
        _mirror.profileIdPointed = vars.profileIdPointed;
        _mirror.pubIdPointed = vars.pubIdPointed;
        _mirror.mirrorId = _mirrorId;
        mirrors[vars.profileId].push(_mirror);

        addRating(vars.profileIdPointed);
        emit mirrored(msg.sender, vars);
    }

    function setLike(
        uint256 _profileId,
        uint256 _profileIdPointed,
        uint256 _postId
    ) external profileOwner(_profileId) pubExist(_profileIdPointed, _postId) {
        require(
            !likes[_profileIdPointed][_postId][_profileId],
            "Like setted yet"
        );
        likes[_profileIdPointed][_postId][_profileId] = true;
        likesCount[_profileIdPointed][_postId]++;
        addRating(_profileIdPointed);
        emit liked(msg.sender, _profileIdPointed, _postId);
    }

    function getPostList(uint256 _profileId)
        external
        view
        returns (uint256[] memory)
    {
        return postList[_profileId];
    }

    function getMirrors(uint256 _profileId)
        external
        view
        returns (Mirrors[] memory)
    {
        return mirrors[_profileId];
    }

    // function getPost(uint256 _profileId, uint256 _pubId) public view returns (Posts calldata){
    //     return posts[_profileId][_pubId];
    // }

    function getComments(uint256 _profileId, uint256 _postId)
        external
        view
        returns (Comments[] memory)
    {
        return comments[_profileId][_postId];
    }

    function getProfile(address _profileAddress)
        external
        view
        returns (uint256)
    {
        return profiles[_profileAddress];
    }

    function addRating(uint256 _profile) internal {
        rating[_profile]++;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {DataTypes} from "./DataTypes.sol";
import {ILensInteractions} from "./ILensInteractions.sol";
import {NFTinStorage} from "./NFTinStorage.sol";

contract LensInteractions is NFTinStorage {
    address public lensAddress;

    ILensInteractions lensHub;

    function setLensHubAddress(address _lensHub) public {
        //for develop
        lensHub = ILensInteractions(_lensHub);
        lensAddress = _lensHub;
    }

    function post(DataTypes.PostData calldata vars)
        public
        returns (bool, uint256)
    {
        (bool success, bytes memory data) = lensAddress.call(
            abi.encodeWithSignature(
                "post((uint256,string,address,bytes,address,bytes))",
                vars
            )
        );

        return (success, abi.decode(data, (uint256)));
    }

    function comment(DataTypes.CommentData calldata vars)
        internal
        returns (bool, uint256)
    {
        (bool success, bytes memory data) = lensAddress.call(
            abi.encodeWithSignature(
                "comment((uint256,string,uint256,uint256,bytes,address,bytes,address,bytes))",
                vars
            )
        );
        return (success, abi.decode(data, (uint256)));
    }

    function mirror(DataTypes.MirrorData calldata vars)
        internal
        returns (bool, uint256)
    {
        (bool success, bytes memory data) = lensAddress.call(
            abi.encodeWithSignature(
                "mirror((uint256,uint256,uint256,bytes,address,bytes))",
                vars
            )
        );
        return (success, abi.decode(data, (uint256)));
    }

    function collect(
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) external {
        lensHub.collect(profileId, pubId, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @title DataTypes
 * @author Lens Protocol
 *
 * @notice A standard library of data types used throughout the Lens Protocol.
 */
library DataTypes {
    /**
     * @notice An enum containing the different states the protocol can be in, limiting certain actions.
     *
     * @param Unpaused The fully unpaused state.
     * @param PublishingPaused The state where only publication creation functions are paused.
     * @param Paused The fully paused state.
     */
    enum ProtocolState {
        Unpaused,
        PublishingPaused,
        Paused
    }

    /**
     * @notice An enum specifically used in a helper function to easily retrieve the publication type for integrations.
     *
     * @param Post A standard post, having a URI, a collect module but no pointer to another publication.
     * @param Comment A comment, having a URI, a collect module and a pointer to another publication.
     * @param Mirror A mirror, having a pointer to another publication, but no URI or collect module.
     * @param Nonexistent An indicator showing the queried publication does not exist.
     */
    enum PubType {
        Post,
        Comment,
        Mirror,
        Nonexistent
    }

    /**
     * @notice A struct containing the necessary information to reconstruct an EIP-712 typed data signature.
     *
     * @param v The signature's recovery parameter.
     * @param r The signature's r parameter.
     * @param s The signature's s parameter
     * @param deadline The signature's deadline
     */
    struct EIP712Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    /**
     * @notice A struct containing profile data.
     *
     * @param pubCount The number of publications made to this profile.
     * @param followModule The address of the current follow module in use by this profile, can be empty.
     * @param followNFT The address of the followNFT associated with this profile, can be empty..
     * @param handle The profile's associated handle.
     * @param imageURI The URI to be used for the profile's image.
     * @param followNFTURI The URI to be used for the follow NFT.
     */
    struct ProfileStruct {
        uint256 pubCount;
        address followModule;
        address followNFT;
        string handle;
        string imageURI;
        string followNFTURI;
    }

    /**
     * @notice A struct containing data associated with each new publication.
     *
     * @param profileIdPointed The profile token ID this publication points to, for mirrors and comments.
     * @param pubIdPointed The publication ID this publication points to, for mirrors and comments.
     * @param contentURI The URI associated with this publication.
     * @param referenceModule The address of the current reference module in use by this profile, can be empty.
     * @param collectModule The address of the collect module associated with this publication, this exists for all publication.
     * @param collectNFT The address of the collectNFT associated with this publication, if any.
     */
    struct PublicationStruct {
        uint256 profileIdPointed;
        uint256 pubIdPointed;
        string contentURI;
        address referenceModule;
        address collectModule;
        address collectNFT;
    }

    /**
     * @notice A struct containing the parameters required for the `createProfile()` function.
     *
     * @param to The address receiving the profile.
     * @param handle The handle to set for the profile, must be unique and non-empty.
     * @param imageURI The URI to set for the profile image.
     * @param followModule The follow module to use, can be the zero address.
     * @param followModuleInitData The follow module initialization data, if any.
     * @param followNFTURI The URI to use for the follow NFT.
     */
    struct CreateProfileData {
        address to;
        string handle;
        string imageURI;
        address followModule;
        bytes followModuleInitData;
        string followNFTURI;
    }

    /**
     * @notice A struct containing the parameters required for the `setDefaultProfileWithSig()` function. Parameters are
     * the same as the regular `setDefaultProfile()` function, with an added EIP712Signature.
     *
     * @param wallet The address of the wallet setting the default profile.
     * @param profileId The token ID of the profile which will be set as default, or zero.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct SetDefaultProfileWithSigData {
        address wallet;
        uint256 profileId;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `setFollowModuleWithSig()` function. Parameters are
     * the same as the regular `setFollowModule()` function, with an added EIP712Signature.
     *
     * @param profileId The token ID of the profile to change the followModule for.
     * @param followModule The followModule to set for the given profile, must be whitelisted.
     * @param followModuleInitData The data to be passed to the followModule for initialization.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct SetFollowModuleWithSigData {
        uint256 profileId;
        address followModule;
        bytes followModuleInitData;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `setDispatcherWithSig()` function. Parameters are the same
     * as the regular `setDispatcher()` function, with an added EIP712Signature.
     *
     * @param profileId The token ID of the profile to set the dispatcher for.
     * @param dispatcher The dispatcher address to set for the profile.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct SetDispatcherWithSigData {
        uint256 profileId;
        address dispatcher;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `setProfileImageURIWithSig()` function. Parameters are the same
     * as the regular `setProfileImageURI()` function, with an added EIP712Signature.
     *
     * @param profileId The token ID of the profile to set the URI for.
     * @param imageURI The URI to set for the given profile image.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct SetProfileImageURIWithSigData {
        uint256 profileId;
        string imageURI;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `setFollowNFTURIWithSig()` function. Parameters are the same
     * as the regular `setFollowNFTURI()` function, with an added EIP712Signature.
     *
     * @param profileId The token ID of the profile for which to set the followNFT URI.
     * @param followNFTURI The follow NFT URI to set.
     * @param sig The EIP712Signature struct containing the followNFT's associated profile owner's signature.
     */
    struct SetFollowNFTURIWithSigData {
        uint256 profileId;
        string followNFTURI;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `post()` function.
     *
     * @param profileId The token ID of the profile to publish to.
     * @param contentURI The URI to set for this new publication.
     * @param collectModule The collect module to set for this new publication.
     * @param collectModuleInitData The data to pass to the collect module's initialization.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     */
    struct PostData {
        uint256 profileId;
        string contentURI;
        address collectModule;
        bytes collectModuleInitData;
        address referenceModule;
        bytes referenceModuleInitData;
    }

    /**
     * @notice A struct containing the parameters required for the `postWithSig()` function. Parameters are the same as
     * the regular `post()` function, with an added EIP712Signature.
     *
     * @param profileId The token ID of the profile to publish to.
     * @param contentURI The URI to set for this new publication.
     * @param collectModule The collectModule to set for this new publication.
     * @param collectModuleInitData The data to pass to the collectModule's initialization.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct PostWithSigData {
        uint256 profileId;
        string contentURI;
        address collectModule;
        bytes collectModuleInitData;
        address referenceModule;
        bytes referenceModuleInitData;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `comment()` function.
     *
     * @param profileId The token ID of the profile to publish to.
     * @param contentURI The URI to set for this new publication.
     * @param profileIdPointed The profile token ID to point the comment to.
     * @param pubIdPointed The publication ID to point the comment to.
     * @param referenceModuleData The data passed to the reference module.
     * @param collectModule The collect module to set for this new publication.
     * @param collectModuleInitData The data to pass to the collect module's initialization.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     */
    struct CommentData {
        uint256 profileId;
        string contentURI;
        uint256 profileIdPointed;
        uint256 pubIdPointed;
        bytes referenceModuleData;
        address collectModule;
        bytes collectModuleInitData;
        address referenceModule;
        bytes referenceModuleInitData;
    }

    /**
     * @notice A struct containing the parameters required for the `commentWithSig()` function. Parameters are the same as
     * the regular `comment()` function, with an added EIP712Signature.
     *
     * @param profileId The token ID of the profile to publish to.
     * @param contentURI The URI to set for this new publication.
     * @param profileIdPointed The profile token ID to point the comment to.
     * @param pubIdPointed The publication ID to point the comment to.
     * @param referenceModuleData The data passed to the reference module.
     * @param collectModule The collectModule to set for this new publication.
     * @param collectModuleInitData The data to pass to the collectModule's initialization.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct CommentWithSigData {
        uint256 profileId;
        string contentURI;
        uint256 profileIdPointed;
        uint256 pubIdPointed;
        bytes referenceModuleData;
        address collectModule;
        bytes collectModuleInitData;
        address referenceModule;
        bytes referenceModuleInitData;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `mirror()` function.
     *
     * @param profileId The token ID of the profile to publish to.
     * @param profileIdPointed The profile token ID to point the mirror to.
     * @param pubIdPointed The publication ID to point the mirror to.
     * @param referenceModuleData The data passed to the reference module.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     */
    struct MirrorData {
        uint256 profileId;
        uint256 profileIdPointed;
        uint256 pubIdPointed;
        bytes referenceModuleData;
        address referenceModule;
        bytes referenceModuleInitData;
    }

    /**
     * @notice A struct containing the parameters required for the `mirrorWithSig()` function. Parameters are the same as
     * the regular `mirror()` function, with an added EIP712Signature.
     *
     * @param profileId The token ID of the profile to publish to.
     * @param profileIdPointed The profile token ID to point the mirror to.
     * @param pubIdPointed The publication ID to point the mirror to.
     * @param referenceModuleData The data passed to the reference module.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct MirrorWithSigData {
        uint256 profileId;
        uint256 profileIdPointed;
        uint256 pubIdPointed;
        bytes referenceModuleData;
        address referenceModule;
        bytes referenceModuleInitData;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `followWithSig()` function. Parameters are the same
     * as the regular `follow()` function, with the follower's (signer) address and an EIP712Signature added.
     *
     * @param follower The follower which is the message signer.
     * @param profileIds The array of token IDs of the profiles to follow.
     * @param datas The array of arbitrary data to pass to the followModules if needed.
     * @param sig The EIP712Signature struct containing the follower's signature.
     */
    struct FollowWithSigData {
        address follower;
        uint256[] profileIds;
        bytes[] datas;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `collectWithSig()` function. Parameters are the same as
     * the regular `collect()` function, with the collector's (signer) address and an EIP712Signature added.
     *
     * @param collector The collector which is the message signer.
     * @param profileId The token ID of the profile that published the publication to collect.
     * @param pubId The publication to collect's publication ID.
     * @param data The arbitrary data to pass to the collectModule if needed.
     * @param sig The EIP712Signature struct containing the collector's signature.
     */
    struct CollectWithSigData {
        address collector;
        uint256 profileId;
        uint256 pubId;
        bytes data;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `setProfileMetadataWithSig()` function.
     *
     * @param profileId The profile ID for which to set the metadata.
     * @param metadata The metadata string to set for the profile and user.
     * @param sig The EIP712Signature struct containing the user's signature.
     */
    struct SetProfileMetadataWithSigData {
        uint256 profileId;
        string metadata;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `toggleFollowWithSig()` function.
     *
     * @param follower The follower which is the message signer.
     * @param profileIds The token ID array of the profiles.
     * @param enables The array of booleans to enable/disable follows.
     * @param sig The EIP712Signature struct containing the follower's signature.
     */
    struct ToggleFollowWithSigData {
        address follower;
        uint256[] profileIds;
        bool[] enables;
        EIP712Signature sig;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {DataTypes} from "./DataTypes.sol";
import {NFTinStorage} from "./NFTinStorage.sol";
interface INFTinLogic {
    function setPost(DataTypes.PostData calldata vars) external;

    function setComment(DataTypes.CommentData calldata vars) external;

    function setMirror(DataTypes.MirrorData calldata vars) external;

    function setLike(
        uint256 _profileId,
        uint256 _profileIdPointed,
        uint256 _postId
    ) external;

    function getPostList(uint256 _profileId)
        external
        view
        returns (uint256[] memory);

    function getMirrors(uint256 _profileId)
        external
        view
        returns (NFTinStorage.Mirrors[] memory);

    function getComments(uint256 _profileId, uint256 _postId)
        external
        view
        returns (NFTinStorage.Comments[] memory);

    function getProfile(address _profileAddress)
        external
        view
        returns (uint256);  
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {DataTypes} from "./DataTypes.sol";

interface ILensInteractions {
    function setDefaultProfileWithSig(DataTypes.SetDefaultProfileWithSigData calldata vars)
        external;

    function setFollowModule(uint256 profileId, address followModule, bytes calldata followModuleData) external;

    function setFollowModuleWithSig(DataTypes.SetFollowModuleWithSigData calldata vars) external;

    function setDispatcher(uint256 profileId, address dispatcher) external;

    function setDispatcherWithSig(DataTypes.SetDispatcherWithSigData calldata vars) external;

    function setProfileImageURI(uint256 profileId, string calldata imageURI) external;

    function setProfileImageURIWithSig(DataTypes.SetProfileImageURIWithSigData calldata vars)
        external;

    function post(DataTypes.PostData calldata vars) external;

    function postWithSig(DataTypes.PostWithSigData calldata vars) external returns (uint256);

    function comment(DataTypes.CommentData calldata vars) external;

    function commentWithSig(DataTypes.CommentWithSigData calldata vars) external returns (uint256);

    function mirror(DataTypes.MirrorData calldata vars) external;

    function mirrorWithSig(DataTypes.MirrorWithSigData calldata vars) external returns (uint256);

    function setFollowNFTURI(uint256 profileId, string calldata followNFTURI) external;

    function follow(uint256[] calldata profileIds, bytes[] calldata datas) external;

    function followWithSig(DataTypes.FollowWithSigData calldata vars)
        external
        returns (uint256[] memory);

    function collect(uint256 profileId, uint256 pubId, bytes calldata data) external;

    function collectWithSig(DataTypes.CollectWithSigData calldata vars) external returns (uint256);

    function burn(uint256 profileId) external;

    function getProfile(uint256 profileId) external view returns (DataTypes.ProfileStruct memory);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {DataTypes} from "./DataTypes.sol";

contract NFTinStorage {
    constructor() {}

    address signer;
    mapping(uint256 => uint256) public rating; //???
    mapping(address => uint256) public profiles; //wallet => profile
    // mapping(uint256 => Posts[]) public posts; // profile => post
    mapping(uint256 => uint256[]) public postList; //profile => [postId]
    mapping(uint256 => uint256[]) public collections; //profile => posts
    mapping(uint256 => mapping(uint256 => Comments[])) public comments; //profile => post => comments[]
    mapping(uint256 => Mirrors[]) public mirrors; //profile => mirrors
    mapping(uint256 => mapping(uint256 => mapping(uint256 => bool)))
        public likes; //profile => post => profile => like
    mapping(uint256 => mapping(uint256 => uint256)) public likesCount; //profile => pub => count

    struct Mirrors {
        uint256 mirrorId;
        uint256 profileIdPointed;
        uint256 pubIdPointed;
    }

    struct Comments {
        uint256 profileId;
        uint256 profileIdPointed; //??
        uint256 pubId;
        uint256 pubIdPointed;
    }

    modifier profileOwner(uint256 _profileId) {
        require(profiles[msg.sender] == _profileId, "Not an owner");
        _;
    }

    modifier pubExist(uint256 _profileIdPointed, uint256 _pubIdPointed) {
        uint256[] memory _postList = postList[_profileIdPointed];
        bool _pubExist;
        for (uint256 i = 0; i < _postList.length; i++) {
            // need gas op
            if (_postList[i] == _pubIdPointed) _pubExist = true;
        }
        require(_pubExist, "Pub doesn`t exist");
        _;
    }

    event profileOnboarded(
        address indexed _profileAddress,
        uint256 indexed _profileId
    );

    event posted(
        address indexed _profileAddress,
        DataTypes.PostData indexed _data
    );

    event commented(
        address indexed _profileAddress,
        DataTypes.CommentData indexed _data
    );

    event mirrored(
        address indexed _profileAddress,
        DataTypes.MirrorData indexed _data
    );

    event liked(
        address indexed _profileAddress,
        uint256 indexed _profileIdPointed,
        uint256 indexed _pubIdPointed
    );
}

// todo:
// write tests
// revards logic
// control mechanism
// owner, profile owner