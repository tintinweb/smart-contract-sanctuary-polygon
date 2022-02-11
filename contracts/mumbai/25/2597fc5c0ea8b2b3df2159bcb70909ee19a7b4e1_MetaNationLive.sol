/**
 *Submitted for verification at polygonscan.com on 2022-02-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract MetaNationLive {
    event StreamCreated(
        bytes32 indexed streamId,
        address indexed streamOwner,
        bytes32 indexed parentId,
        bytes32 contentId,
        bytes32 categoryId
    );
    event ContentAdded(bytes32 indexed contentId, string contentUri);
    event CategoryCreated(bytes32 indexed categoryId, string category);
    event Voted(
        bytes32 indexed streamId,
        address indexed streamOwner,
        address indexed voter,
        uint80 reputationstreamOwner,
        uint80 reputationVoter,
        int40 streamVotes,
        bool up,
        uint8 reputationAmount
    );
    //
    event Subscribed(
        bytes32 indexed streamId,
        address indexed streamOwner,
        address indexed subscriber,
        uint80 subscribersstreamOwner,
        uint80 reputationSubscriber,
        int40 streamSubscribers,
        bool up
        // uint8 reputationAmount
    );
    //
    struct stream {
        address streamOwner;
        bytes32 parentStream;
        bytes32 contentId;
        int40 votes;
        int40 subscribers; //
        bytes32 categoryId;
    }

    mapping(address => mapping(bytes32 => uint80)) reputationRegistry;
    mapping(bytes32 => string) categoryRegistry;
    mapping(bytes32 => string) contentRegistry;
    mapping(bytes32 => stream) streamRegistry;
    mapping(address => mapping(bytes32 => bool)) voteRegistry;
    mapping(address => mapping(bytes32 => bool)) subscriberRegistry;

    function createstream(
        bytes32 _parentId,
        string calldata _contentUri,
        bytes32 _categoryId
    ) external {
        address _owner = msg.sender;
        bytes32 _contentId = keccak256(abi.encode(_contentUri));
        bytes32 _streamId = keccak256(
            abi.encodePacked(_owner, _parentId, _contentId)
        );
        contentRegistry[_contentId] = _contentUri;
        streamRegistry[_streamId].streamOwner = _owner;
        streamRegistry[_streamId].parentStream = _parentId;
        streamRegistry[_streamId].contentId = _contentId;
        streamRegistry[_streamId].categoryId = _categoryId;
        emit ContentAdded(_contentId, _contentUri);
        emit StreamCreated(
            _streamId,
            _owner,
            _parentId,
            _contentId,
            _categoryId
        );
    }

function subscribe(bytes32 _streamId) external {
        address _subscriber = msg.sender;
        bytes32 _category = streamRegistry[_streamId].categoryId;
        address _contributor = streamRegistry[_streamId].streamOwner;
        require(
            streamRegistry[_streamId].streamOwner != _subscriber,
            "You cannot subscribe your own stream"
        );
        require(
            subscriberRegistry[_subscriber][_streamId] == false,
            "Sender already subscribed this stream"
        );
        streamRegistry[_streamId].subscribers += 1;
        subscriberRegistry[_subscriber][_streamId] = true;
        emit Subscribed(
            _streamId,
            _contributor,
            _subscriber,
            reputationRegistry[_contributor][_category],
            reputationRegistry[_subscriber][_category],
            streamRegistry[_streamId].subscribers,
            true
        );
    }

function unSubscribe(bytes32 _streamId) external {
        address _subscriber = msg.sender;
        bytes32 _category = streamRegistry[_streamId].categoryId;
        address _contributor = streamRegistry[_streamId].streamOwner;
        require(
            subscriberRegistry[_subscriber][_streamId] == false,
            "Sender already subscribed this stream"
        );
        streamRegistry[_streamId].subscribers >= 1
            ? streamRegistry[_streamId].subscribers -= 1
            : streamRegistry[_streamId].subscribers = 0;
        subscriberRegistry[_subscriber][_streamId] = true;
        emit Subscribed(
            _streamId,
            _contributor,
            _subscriber,
            reputationRegistry[_contributor][_category],
            reputationRegistry[_subscriber][_category],
            streamRegistry[_streamId].subscribers,
            false
        );
    }

    function voteUp(bytes32 _streamId, uint8 _reputationAdded) external {
        address _voter = msg.sender;
        bytes32 _category = streamRegistry[_streamId].categoryId;
        address _contributor = streamRegistry[_streamId].streamOwner;
        require(
            streamRegistry[_streamId].streamOwner != _voter,
            "You cannot vote your own stream"
        );
        require(
            voteRegistry[_voter][_streamId] == false,
            "Sender already voted this stream"
        );
        require(
            validateReputationChange(_voter, _category, _reputationAdded) ==
                true,
            "This address cannot add this amount of reputation points"
        );
        streamRegistry[_streamId].votes += 1;
        reputationRegistry[_contributor][_category] += _reputationAdded;
        voteRegistry[_voter][_streamId] = true;
        emit Voted(
            _streamId,
            _contributor,
            _voter,
            reputationRegistry[_contributor][_category],
            reputationRegistry[_voter][_category],
            streamRegistry[_streamId].votes,
            true,
            _reputationAdded
        );
    }

    function voteDown(bytes32 _streamId, uint8 _reputationTaken) external {
        address _voter = msg.sender;
        bytes32 _category = streamRegistry[_streamId].categoryId;
        address _contributor = streamRegistry[_streamId].streamOwner;
        require(
            voteRegistry[_voter][_streamId] == false,
            "Sender already voted in this stream"
        );
        require(
            validateReputationChange(_voter, _category, _reputationTaken) ==
                true,
            "This address cannot take this amount of reputation points"
        );
        streamRegistry[_streamId].votes >= 1
            ? streamRegistry[_streamId].votes -= 1
            : streamRegistry[_streamId].votes = 0;
        reputationRegistry[_contributor][_category] >= _reputationTaken
            ? reputationRegistry[_contributor][_category] -= _reputationTaken
            : reputationRegistry[_contributor][_category] = 0;
        voteRegistry[_voter][_streamId] = true;
        emit Voted(
            _streamId,
            _contributor,
            _voter,
            reputationRegistry[_contributor][_category],
            reputationRegistry[_voter][_category],
            streamRegistry[_streamId].votes,
            false,
            _reputationTaken
        );
    }

    function validateReputationChange(
        address _sender,
        bytes32 _categoryId,
        uint8 _reputationAdded
    ) internal view returns (bool _result) {
        uint80 _reputation = reputationRegistry[_sender][_categoryId];
        if (_reputation < 2) {
            _reputationAdded == 1 ? _result = true : _result = false;
        } else {
            2**_reputationAdded <= _reputation
                ? _result = true
                : _result = false;
        }
    }

    function addCategory(string calldata _category) external {
        bytes32 _categoryId = keccak256(abi.encode(_category));
        categoryRegistry[_categoryId] = _category;
        emit CategoryCreated(_categoryId, _category);
    }

    function getContent(bytes32 _contentId)
        public
        view
        returns (string memory)
    {
        return contentRegistry[_contentId];
    }

    function getCategory(bytes32 _categoryId)
        public
        view
        returns (string memory)
    {
        return categoryRegistry[_categoryId];
    }

    function getReputation(address _address, bytes32 _categoryID)
        public
        view
        returns (uint80)
    {
        return reputationRegistry[_address][_categoryID];
    }

    function getStream(bytes32 _streamId)
        public
        view
        returns (
            address,
            bytes32,
            bytes32,
            int72,
            int72,
            bytes32
        )
    {
        return (
            streamRegistry[_streamId].streamOwner,
            streamRegistry[_streamId].parentStream,
            streamRegistry[_streamId].contentId,
            streamRegistry[_streamId].votes,
            streamRegistry[_streamId].subscribers,
            streamRegistry[_streamId].categoryId
        );
    }
}