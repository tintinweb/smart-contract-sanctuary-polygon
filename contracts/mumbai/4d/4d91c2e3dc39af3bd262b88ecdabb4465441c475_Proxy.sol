/**
 *Submitted for verification at polygonscan.com on 2022-09-26
*/

contract Proxy {
    
    struct Setting{
        address implementation;
        address owner;
    }

    

    

    event Modified(address implementation,address owner);

    constructor(address _implementation, address _owner){
        
        bytes32 position= bytes32('implementation');

        Setting storage setting;

        assembly {
            setting.slot:=position
        }
        
        setting.implementation=_implementation;
        setting.owner=_owner;

    }

    function _setting() internal pure returns(Setting storage setting){
        bytes32 position= bytes32('implementation');

        assembly {
            setting.slot:=position
        }
    }

    function modify(address _implementation, address _owner) external {
        Setting storage setting=_setting();
        setting.implementation=_implementation;
        setting.owner=_owner;
        emit Modified(_implementation,_owner);
    }




    function _delegate(address _imp) internal virtual {
        assembly {
            // calldatacopy(t, f, s)
            // copy s bytes from calldata at position f to mem at position t
            calldatacopy(0, 0, calldatasize())

            // delegatecall(g, a, in, insize, out, outsize)
            // - call contract at address a
            // - with input mem[in…(in+insize))
            // - providing g gas
            // - and output area mem[out…(out+outsize))
            // - returning 0 on error and 1 on success
            let result := delegatecall(gas(), _imp, 0, calldatasize(), 0, 0)

            // returndatacopy(t, f, s)
            // copy s bytes from returndata at position f to mem at position t
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                // revert(p, s)
                // end execution, revert state changes, return data mem[p…(p+s))
                revert(0, returndatasize())
            }
            default {
                // return(p, s)
                // end execution, return data mem[p…(p+s))
                return(0, returndatasize())
            }
        }
    }

    fallback() external payable {
        Setting storage setting=_setting();
        address implementation =setting.implementation;
        _delegate(implementation);
    }

    receive() external payable{
        
    }


    
}