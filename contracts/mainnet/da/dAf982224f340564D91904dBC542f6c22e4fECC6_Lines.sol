// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lines {
  struct Line {
    string str;
    uint256 edits;
    address lastEditor;
  }

  struct ExportLine {
    int256 uid;
    string str;
    uint256 edits;
  }

  mapping(int256 => Line) lines;
  mapping(address => uint256) _pendingMatic;

  uint256 public LINE_LENGTH;
  uint256 public LINE_PRICE;

  event LineUpdated(int256 indexed uid, string str, uint256 edits);

  address public devAddress;

  constructor(uint256 lineLength, uint256 linePrice) {
    LINE_LENGTH = lineLength;
    LINE_PRICE = linePrice;
    devAddress = msg.sender;
  }

  function uploadLines(string[] calldata strings, int256[] calldata uids) public payable {
    require(strings.length == uids.length, "Arrays lengths do not match");
    uint256 value = msg.value;

    for (uint256 i = 0; i < strings.length; i++) {
      require(bytes(strings[i]).length <= LINE_LENGTH, "Unexpected line length");

      uint256 thisPrice = lines[uids[i]].edits * LINE_PRICE;

      require(value >= thisPrice, "Not enough funds");

      value -= thisPrice;

      if (thisPrice > 0) {
        uint256 devReward = thisPrice / 10;
        uint256 lastEditorReward = thisPrice - devReward;
        _pendingMatic[devAddress] += devReward;
        _pendingMatic[lines[uids[i]].lastEditor] += lastEditorReward;
      }

      lines[uids[i]].str = strings[i];
      lines[uids[i]].edits++;

      lines[uids[i]].lastEditor = msg.sender;

      emit LineUpdated(uids[i], lines[uids[i]].str, lines[uids[i]].edits);
    }
  }

  function getLines(int256 startIndex, int256 amount) public view returns (ExportLine[] memory out) {
    require(amount > 0, "Negative or null amount");

    out = new ExportLine[](uint256(amount));

    for (int256 i = startIndex; i < startIndex + amount; i++) {
      Line memory _line = lines[i];
      out[uint256(i - startIndex)].uid = i;
      out[uint256(i - startIndex)].str = _line.str;
      out[uint256(i - startIndex)].edits = _line.edits;
    }

    return out;
  }

  function getLinesUnordered(int256[] calldata uids) public view returns (ExportLine[] memory out) {
    out = new ExportLine[](uids.length);
    for (uint256 i = 0; i < uids.length; i++) {
      int256 uid = uids[i];
      Line memory _line = lines[uid];
      out[i].uid = uid;
      out[i].str = _line.str;
      out[i].edits = _line.edits;
    }
    return out;
  }

  function abs(int256 x) private pure returns (int256) {
    return x >= 0 ? x : -x;
  }

  function pendingMatic(address addr) public view returns (uint256) {
    return _pendingMatic[addr];
  }

  function withdraw() public {
    require(_pendingMatic[msg.sender] > 0, "Nothing to withdraw");
    uint256 amount = _pendingMatic[msg.sender];
    _pendingMatic[msg.sender] = 0;
    (bool success, ) = payable(msg.sender).call{value: amount}("");
    require(success, "Transfer failed.");
  }

  function changeDevAddress(address newDevAddress) public {
    require(msg.sender == devAddress, "Not dev");
    devAddress = newDevAddress;
  }
}