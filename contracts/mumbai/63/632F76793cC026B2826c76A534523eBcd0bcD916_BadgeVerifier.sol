// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IOtoCoMasterV2.sol";

uint256 constant STATICGAS = 0x7530;
bytes4 constant ISOWNER = 0x2f54bf6e;
bytes4 constant TOKEN = 0xfc0c546a;
bytes4 constant BALANCEOF = 0x70a08231;
bytes4 constant GETMANAGER = 0xd5009584;


contract BadgeVerifier {

  enum Badges {
    NoBadges, // 0 := None of the below or Entity closed/non existent.
    Owner,    // 1 := Current tokenId's owner.
    Signer,   // 2 := Member of the tokenId's Multisig owner.
    Member,   // 3 := Member of a DAO contract (Entitled to Governor's token shares).
    Manager   // 4 := Manager of a DAO contract.
  }

  struct Data {
    uint256 tokenId; address account;
  }

  IOtoCoMasterV2 public master;

  constructor(address _master) payable {
    assembly {
      sstore(master.slot, _master)
    }
  }

  function getBadges(Data memory data) 
    public 
    returns(Badges[] memory badges) 
  {
    ( ,,,, string memory name ) = 
    master.series(data.tokenId);
    Badges[] memory buffer = 
      new Badges[](0x01);

    // Non-Existent/Closed Case
    if ( bytes(name).length == 0 ) {
      buffer[0] = Badges.NoBadges; 
      return badges = buffer;    
    } else {

    // Owner/EOA Case
    address owner = 
      master.ownerOf(data.tokenId);
    if ( owner.code.length == 0 ) {
      owner == data.account 
      ? buffer[0] = Badges.Owner 
      : buffer[0] = Badges.NoBadges; 
      return badges = buffer;
    } else {

    // Signer/Multisig Case
    if (_isOwner(data.account, owner)) {
      buffer[0] = Badges.Signer; 
      return badges = buffer;
    } else {

    // Governor Cases (Member, Manager)
    (bool isManager, bool isMember) = 
      _governorStats(data.account, owner);
    badges = _governorHandler(isManager, isMember);
    return badges;
    
    // truncate padding
    /* */}/* */}/* */}

    }

  function getBadgeState(Data memory data) 
      external 
      returns(bool stdout) 
  {
    return getBadges(data)[0] != Badges.NoBadges;
  }

    function _governorHandler(bool _isManager, bool _isMember) 
      private 
      pure 
      returns (Badges[] memory _badges)
    {
      assembly {
        for {} iszero(0x0) {} {
          switch or(_isManager, _isMember)
          case 0 {
            // (0,0)
            _badges := mload(0x40)
            mstore( // Length
              add(_badges, 0x00), 0x01)
            mstore( // Badges.NoBadges
              add(_badges, 0x20), 0x00) 
            mstore( // Return value
              0x40, add(_badges, 0x40))
            break
          }
          case 1 {
            switch and(_isManager, _isMember)
            case 1 {
              // (1,1)
              _badges := mload(0x40)
              mstore( // Length
                add(_badges, 0x00), 0x02)
              mstore( // Badges.Member
                add(_badges, 0x20), 0x03) 
              mstore( // Badges.Manager
                add(_badges, 0x40), 0x04) 
              mstore( // Return value
                0x40, add(_badges, 0x60))
              break
            }
            case 0 {
              switch iszero(_isManager)
              case 1 {
                // (0,1)
                _badges := mload(0x40)
                mstore( // Length
                  add(_badges, 0x00), 0x01)
                mstore( // Badges.Member
                  add(_badges, 0x20), 0x03) 
                mstore( // Return value
                  0x40, add(_badges, 0x40))
                break
              }
              case 0 {
                // (1,0)
                _badges := mload(0x40)
                mstore( // Length
                  add(_badges, 0x00), 0x01)
                mstore( // Badges.Manager
                  add(_badges, 0x20), 0x04) 
                mstore( // Return value
                  0x40, add(_badges, 0x40))
                break
              }
            }
          }
          invalid()
        }
      }
    }

  function _isOwner(address _account, address _multisig)
    private
    returns (bool _stdout)
  {
    bytes memory encoded = 
      abi.encodeWithSelector(
        ISOWNER,
        _account
    );
    bool success;
    assembly {
      success := call(
        STATICGAS, 
        _multisig, 
        0x00,
        add(encoded, 0x20), 
        mload(encoded),
        0x00, 
        0x20
      )
      _stdout := and(success, mload(0x00))
    }
  }

  function _governorStats(address _account, address _governor)
    private
    view
    returns (bool _manager, bool _member) 
  {
    bytes memory encoded = 
      abi.encodeWithSelector(BALANCEOF, _account);

    assembly {
      mstore(returndatasize(), TOKEN)
      
      pop(
        staticcall(
          STATICGAS,
          _governor,
          0x00, 0x04,
          0x00, 0x20
        )
      )
      pop(
        staticcall(
          STATICGAS,
          mload(0x00),
          add(encoded, 0x20),
          mload(encoded),
          0x00,
          0x20
        )
      ) 
      let bal := mload(0x00)
      mstore(0x00, GETMANAGER)
      pop(
        staticcall(
        STATICGAS,
        _governor,
        0x00, 0x04,
        0x00, 0x20
        )
      ) 
      _manager := eq(_account, mload(0x00))
      _member := iszero(iszero(bal))
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IOtoCoJurisdiction {
    function getSeriesNameFormatted(uint256 count, string calldata nameToFormat) external pure returns(string memory);
    function getJurisdictionName() external view returns(string memory);
    function getJurisdictionBadge() external view returns(string memory);
    function getJurisdictionGoldBadge() external view returns(string memory);
    function getJurisdictionRenewalPrice() external view returns(uint256);
    function getJurisdictionDeployPrice() external view returns(uint256);
    function isStandalone() external view returns(bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IOtoCoJurisdiction.sol";

interface IOtoCoMasterV2 {

    struct Series {
        uint16 jurisdiction;
        uint16 entityType;
        uint64 creation;
        uint64 expiration;
        string name;
    }

    function owner() external  view returns (address);

    function series(uint256 tokenId) external view returns (uint16, uint16, uint64, uint64, string memory);
    function jurisdictionAddress(uint16 jurisdiction) external view returns (IOtoCoJurisdiction j);
    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev See {OtoCoMaster-baseFee}.
     */
    function baseFee() external view returns (uint256 fee);
    function externalUrl() external view returns (string calldata);
    function getSeries(uint256 tokenId) external view returns (Series memory);
    receive() external payable;
    function docs(uint256 tokenId) external view returns(string memory);
}