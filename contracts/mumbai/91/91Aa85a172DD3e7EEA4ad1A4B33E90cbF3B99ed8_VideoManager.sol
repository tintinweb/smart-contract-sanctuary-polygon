pragma solidity ^0.8.4;

contract VideoManager {

struct Video {
	address creator;
	uint256 price;
	uint256 referalFee; //number out of 1000
	uint256 publishingFee; //number out of 1000
	//address[] tokensAccepted;
	string ipfsHash;
	bool disabled; 
}

mapping(string => Video) public videos;
mapping(string => mapping(address => bool)) public videoAccess;

error WrongPrice();
error SendError();
error VideoExists();
error VideoDoesNotExist();
error VideoDisabledError();
error DoNotOwnVideo();

event VideoCreated(address creator, uint256 price, string videoHash, uint256 referalFee, uint256 publisherFee);
event VideoEdited(address creator, uint256 price, string videoHash, uint256 referalFee, uint256 publisherFee);
event VideoPurchased(address buyer, uint256 price, address refferer, string videoHash, address publisher);
event VideoDisabled(string videoHash, address creator);
event VideoEnabled(string videoHash, address creator);


constructor() {}

function getVideoAccess(string calldata _videoHash, address _referrer, address _publisher) external payable {

	if(videos[_videoHash].creator == address(0)) revert VideoDoesNotExist();
	if(videos[_videoHash].disabled) revert VideoDisabledError();

	if(msg.value < videos[_videoHash].price) revert WrongPrice();

	uint256 creatorAmount = msg.value;

	if(_referrer != address(0)) {
		uint256 referalAmount = msg.value * videos[_videoHash].referalFee / 1000;
	   (bool success1, ) = _referrer.call{value:referalAmount}("");
		if(!success1) revert SendError();
		creatorAmount-= referalAmount;
	}

	if(_publisher != address(0)) {
		uint256 publisherAmount = msg.value * videos[_videoHash].publishingFee / 1000;	   
		(bool success2, ) = _publisher.call{value:publisherAmount}("");
		if(!success2) revert SendError();
		creatorAmount-= publisherAmount;
	}

	(bool success, ) = videos[_videoHash].creator.call{value:creatorAmount}("");
	if(!success) revert SendError();

	videoAccess[_videoHash][msg.sender] = true;

	emit VideoPurchased(msg.sender, msg.value, _referrer, _videoHash, _publisher);
}

function createVideo(uint256 _price, string calldata _videoHash, uint256 _referalFee, uint256 _publisherFee) external {

	if(videos[_videoHash].creator != address(0)) revert VideoExists();

	Video memory newVideo;
	newVideo.creator = msg.sender;
	newVideo.price = _price;
	newVideo.ipfsHash = _videoHash;
	newVideo.referalFee = _referalFee;
	newVideo.publishingFee = _publisherFee;
	videos[_videoHash] = newVideo;

	videoAccess[_videoHash][msg.sender] = true; 

	emit VideoCreated(msg.sender, _price, _videoHash, _referalFee, _publisherFee);
}

function editVideo(uint256 _price, string calldata _videoHash, uint256 _referalFee, uint256 _publisherFee) external {
	if(videos[_videoHash].creator != msg.sender) revert DoNotOwnVideo();
	Video memory newVideo;
	newVideo.creator = msg.sender;
	newVideo.price = _price;
	newVideo.ipfsHash = _videoHash;
	newVideo.referalFee = _referalFee;
	newVideo.publishingFee = _publisherFee;
	videos[_videoHash] = newVideo;

	emit VideoEdited(msg.sender, _price, _videoHash, _referalFee, _publisherFee);
}

function disableVideo(string calldata _videoHash) external {
	if(videos[_videoHash].creator != msg.sender) revert DoNotOwnVideo();
	videos[_videoHash].disabled = true;
	emit VideoDisabled(_videoHash, msg.sender);
}

function enableVideo(string calldata _videoHash) external {
	if(videos[_videoHash].creator != msg.sender) revert DoNotOwnVideo();
	videos[_videoHash].disabled = false;
	emit VideoEnabled(_videoHash, msg.sender);
} 


}