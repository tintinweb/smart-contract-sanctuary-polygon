/**
 *Submitted for verification at polygonscan.com on 2023-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

abstract contract Governance {

    address _governance;

    constructor() {
        _governance = tx.origin;
    }

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyGovernance {
        require(msg.sender == _governance, "not governance");
        _;
    }

    function setGovernance(address governance)  public  onlyGovernance
    {
        require(governance != address(0), "new governance the zero address");
        emit GovernanceTransferred(_governance, governance);
        _governance = governance;
    }
}

interface IBODY
{
    function Metadata_Update(uint256 tokenId) external;
}

interface IATTR
{
    function getTraits(uint256 fishid) external view returns ( bytes memory );
    function nextTrait(uint256 fishid) external view returns ( bool );
    function countingNodes( uint256 sum ) external view returns( uint256 );
    function addrNodes( address[] memory nodes, uint256 index ) external view returns ( address[] memory );
    function pattenInfo(uint256 idx) external view returns(bytes memory);
}

contract IdAttr is Governance {
   
    string public thisTrait; 
    bytes constant empty = hex"";

    address public nextnode = address(0x0);
    address public bodyAddress = address(0x0);
    IBODY _body = IBODY(bodyAddress);

    bytes[] public idPatterns;
    uint256 public totalPattern = 1;
    
    bytes constant svg_begin_g = hex"3c7376672077696474683d2735303027206865696768743d273530302720786d6c6e733d27687474703a2f2f7777772e77332e6f72672f323030302f737667273e3c673e";
    bytes constant svg_end_g = hex"3c2f673e3c2f7376673e";
   
    mapping(uint256 => string) t_attr;
    mapping(uint256 => uint256) t_type;
    mapping (address => bool) public operator;
    
    event updatedAttr(uint256 tokenid);
    event updatebatch(uint256[] tokenIds);

    constructor(string memory trait) 
    { 
        thisTrait = trait;
        operator[msg.sender] = true;
        idPatterns.push(empty);
    }

    function updated_Attr( uint256 tokenId, string memory new_attr, uint256 update_type ) public {
        
        require(operator[msg.sender], "invalid operator");
        require(update_type < totalPattern, "update_type invalid");

        t_attr[tokenId] = new_attr;
        t_type[tokenId] = update_type;

        if( bodyAddress != address(0x0) )
        {
           _body.Metadata_Update(tokenId);
        }
        emit updatedAttr(tokenId);
    }

    function batchupdated( uint256[] memory tokenIds, string[] memory new_attr, uint256[] memory update_type ) public {
        
        require(operator[msg.sender], "invalid operator");

        for(uint i = 0; i < tokenIds.length; i++)
        {
            require(update_type[i] < totalPattern, "update_type invalid");
            uint256 id = tokenIds[i];
            t_attr[id] = new_attr[i];
            t_type[id] = update_type[i];

            if( bodyAddress != address(0x0) )
            {
                _body.Metadata_Update(id);
            }           
        }
        emit updatebatch(tokenIds);
    }

    function setNodenext( address _next_node ) external onlyGovernance
    {
        nextnode = _next_node;
    }
    
    function StringToBytes(string memory _string) internal pure returns (bytes memory) {
        return (abi.encodePacked(_string));
    }

    function addPattern( string memory pattstr ) external onlyGovernance
    {
        idPatterns.push( StringToBytes(pattstr) );
        totalPattern = totalPattern + 1;
    }

    function setBodyAddress( address _bodyaddr ) external onlyGovernance
    {
        bodyAddress = _bodyaddr;
        _body = IBODY(bodyAddress);
    }

    function addOperator(address _operator) public onlyGovernance 
    {
        operator[_operator] = true;
    }
    
    function removeOperator(address _operator) public onlyGovernance 
    {
        operator[_operator] = false;
    }

    function nextTrait(uint256 theid) public view returns ( bool )
    {
        bool now_state = false;
        uint256 draw_idx =  theid; 
        
        if( draw_idx != 0 )
        {
            if( bytes(t_attr[draw_idx]).length != 0)
                now_state = true;
            if ( nextnode != address(0x0) )
            {
                    IATTR _egg = IATTR(nextnode);
                    bool next_state = _egg.nextTrait(theid);
                    return (now_state || next_state);
            }  
        }
        else{
            if ( nextnode != address(0x0) )
            {
                    IATTR _egg = IATTR(nextnode);
                    bool next_state = _egg.nextTrait(theid);
                    return (now_state || next_state);
            }           
        }
        return now_state;         
    }

    function getTraits(uint256 theid) public view returns ( bytes memory )
    {
        bytes memory now_trait = empty;
        bool now_state = false;
        uint256 draw_idx =  theid; 

        if( draw_idx != 0 )
        {
            if( bytes(t_attr[draw_idx]).length != 0)
            {
                now_trait = abi.encodePacked(' {"trait_type": "',thisTrait,'", "value": "',t_attr[draw_idx],'"}');
                now_state = true; 
            }
            if ( nextnode != address(0x0) )
            {
                    IATTR _egg = IATTR(nextnode);
                    bytes memory _datas = _egg.getTraits(theid);
                    bool next_state = _egg.nextTrait(theid);
                    if( now_state && next_state )
                    {
                       return abi.encodePacked(  now_trait, ',', _datas );
                    }
                    return abi.encodePacked(  now_trait, _datas );
            }
        }
        else{
            if ( nextnode != address(0x0) )
            {
                    IATTR _egg = IATTR(nextnode);
                    bytes memory _datas = _egg.getTraits(theid);
                    bool next_state = _egg.nextTrait(theid);
                    if( now_state && next_state )
                    {
                       return abi.encodePacked(  now_trait, ',', _datas );
                    }
                    return abi.encodePacked(  now_trait, _datas );
            }           
        }
        return now_trait;
    } 

    function countingNodes( uint256 sum ) public view returns( uint256 )
    {
        sum = sum + 1;
        if ( nextnode != address(0x0) )
        {
            IATTR _egg = IATTR(nextnode);
            return _egg.countingNodes(sum);
        }
        return sum;       
    }

    function addrNodes( address[] memory nodes, uint256 index ) public view returns ( address[] memory )
    {
        nodes[index] = address(this);
        if ( nextnode != address(0x0) )
        {
            IATTR _egg = IATTR(nextnode);
            return _egg.addrNodes( nodes, (index + 1) );
        }
        return nodes;
    }

    function getValue(uint256 tokenid) public view returns( string memory )
    {
        return t_attr[tokenid];       
    }

    function getPattern(uint256 tokenid) public view returns( bytes memory )
    {
        return idPatterns[ t_type[tokenid] ];     
    }

    function pattenInfo(uint256 idx) public view returns(bytes memory)
    {
        bytes memory _patt_1 = hex"";

        _patt_1 = getPattern(idx);

        if ( nextnode != address(0x0) )
        {
            IATTR _egg = IATTR(nextnode);
            return  bytes.concat(_patt_1, _egg.pattenInfo(idx) );
        }
        return _patt_1; 
    }

    /**
     * @notice Generate SVG, b64 encode it.
     */
    function b64svgPattern(uint256 num)
        public
        view
        returns (string memory)
    {
        return string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(bytes.concat( bytes.concat( svg_begin_g, idPatterns[num]), svg_end_g) )
                )
        );
    }

    function stringTobytes(string memory str_data) public pure returns(bytes memory)
   {
       return abi.encodePacked(str_data);
   }

    function bytesToString(bytes memory byteCode) public pure returns(string memory stringData)
    {
        uint256 blank = 0; //blank 32 byte value
        uint256 length = byteCode.length;

        uint cycles = byteCode.length / 0x20;
        uint requiredAlloc = length;

        if (length % 0x20 > 0) //optimise copying the final part of the bytes - to avoid looping with single byte writes
        {
            cycles++;
            requiredAlloc += 0x20; //expand memory to allow end blank, so we don't smack the next stack entry
        }

        stringData = new string(requiredAlloc);

        //copy data in 32 byte blocks
        assembly {
            let cycle := 0

            for
            {
                let mc := add(stringData, 0x20) //pointer into bytes we're writing to
                let cc := add(byteCode, 0x20)   //pointer to where we're reading from
            } lt(cycle, cycles) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
                cycle := add(cycle, 0x01)
            } {
                mstore(mc, mload(cc))
            }
        }

        //finally blank final bytes and shrink size (part of the optimisation to avoid looping adding blank bytes1)
        if (length % 0x20 > 0)
        {
            uint offsetStart = 0x20 + length;
            assembly
            {
                let mc := add(stringData, offsetStart)
                mstore(mc, mload(add(blank, 0x20)))
                //now shrink the memory back so the returned object is the correct size
                mstore(stringData, length)
            }
        }
    }

    function svgPattern(uint256 num)
        public
        view
        returns (string memory)
    {
        return bytesToString(idPatterns[num]);
    }   

}