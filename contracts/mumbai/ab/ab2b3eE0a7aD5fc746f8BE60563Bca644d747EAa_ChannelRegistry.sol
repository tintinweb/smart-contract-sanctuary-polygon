//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/* import "hardhat/console.sol"; */

contract ChannelRegistry {
  event NewChannel(uint id, address owner, string cid, bool active);
  event UpdateChannel(uint id, address owner, string cid, bool active);
  event ToggleActive(uint id, address owner, string cid, bool active);

  struct Channel {
    address owner;
    // IPFS CID
    string cid;
    bool active;
    uint  id;
  }

  Channel[] private channels;

  mapping(address => uint[]) private ownerToChannels;
  mapping (uint => address) private channelToOwner;

  constructor() {
      /* console.log("Deploying ChannelRegistry ..."); */
  }

  // we don't do any checks for duplicates here, not yet.
  function createChannel(string memory _cid) public {
    channels.push(Channel(msg.sender, _cid, true, channels.length));
    uint id =  channels.length - 1;

    ownerToChannels[msg.sender].push(id);
    channelToOwner[id] = msg.sender;
    /* console.log("Added a channel, id : ", id); */
    emit NewChannel(id, msg.sender, _cid, true);
  }

  function updateChannel(uint id, string memory _cid) public {
    address ownerAddress = channelToOwner[id];
    // make sure that the sender is the owner of the channel
    require(ownerAddress == msg.sender);
    Channel memory channel = channels[id];
    channel.cid   = _cid;
    channels[id] = channel;
    /* console.log("Updated channel, id : ", id); */
    emit UpdateChannel(id, msg.sender, _cid, channel.active);
  }

  function toggleActive(uint id) public {
    address ownerAddress = channelToOwner[id];
    // make sure that the sender is the owner of the channel
    require(ownerAddress == msg.sender);
    Channel memory channel = channels[id];
    channel.active = !channel.active;
    channels[id] = channel;
    /* console.log("Toggled active for channel, id : ", id); */
    emit ToggleActive(id, msg.sender, channel.cid, channel.active);
  }

  function getChannelsByOwner(address owner) public view returns (Channel[] memory) {
    uint[] memory channelIds = ownerToChannels[owner];
    Channel[] memory _channels = new Channel[](channelIds.length);
    Channel memory _channel;
    for (uint i = 0; i < channelIds.length; i++) {
      _channel = channels[channelIds[i]];
      _channels[i] = _channel;
    }
    return _channels;
  }

  function getChannel(uint id) public view returns (Channel memory) {
    require(id < channels.length);
    Channel memory _channel = channels[id];
    return _channel;
  }


}