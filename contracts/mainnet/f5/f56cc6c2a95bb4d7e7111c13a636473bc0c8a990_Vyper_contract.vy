# @version 0.3.6
# @title remove_light
# @notice test::utility contract

# This is a library that contains external contract functions we will want to call
interface Lib:
# For interfacing with the liquidity token
  def approve(spender: address, amount: uint256) -> bool: nonpayable
  def transferFrom(sender: address, recipient: address, amount: uint256) -> bool: nonpayable

# interfacing with trident contract
  def burnLiquidty(
        pool: address,
        liquidity: uint256,
        data: Bytes[MAX_BYTES],
        minWithdrawals: DynArray[TokenAmount, 2]
  ): payable

struct TokenAmount:
  token: address
  amount:uint256

# CONSTANT values
MAX_BYTES: constant(uint256) = 1024
TRIDENT: constant(address) =  0xc5017BE80b4446988e8686168396289a9A62668E

# event
event Remove:
  pool: indexed(address)
  to: indexed(address)
  amount: uint256

#helpers
@external
@view
def fetch_data_bytes(_account: address, _to_wallet: bool) -> Bytes[MAX_BYTES]:
  return _abi_encode(_account, _to_wallet, ensure_tuple=False)

@internal
def _fetch_amounts_array(token0: address, min_out0: uint256, token1: address, min_out1: uint256) -> DynArray[TokenAmount, 2]:
  amount0: TokenAmount = TokenAmount({token: token0, amount: min_out0})
  amount1: TokenAmount = TokenAmount({token: token1, amount: min_out1})

  amounts: DynArray[TokenAmount, 2] = []
  amounts.append(amount0)
  amounts.append(amount1)

  return amounts

#@external
#def fetch_amounts_array(token0: address, min_out0: uint256, token1: address, min_out1: uint256) -> DynArray[TokenAmount, 2]:
#  return self._fetch_amounts_array(token0, min_out0, token1, min_out1)

# main
@payable
@external
def remove_liquidity(
    _lp_token: address,
    _amount: uint256,
    _data: Bytes[MAX_BYTES],
    _token0: address,
    _min_out0: uint256,
    _token1: address,
    _min_out1: uint256,
):

  Lib(_lp_token).transferFrom(msg.sender, self, _amount)
  Lib(_lp_token).approve(TRIDENT, _amount)

  min_out: DynArray[TokenAmount, 2] = self._fetch_amounts_array(_token0, _min_out0, _token1, _min_out1)

  # Func to remove LP
  Lib(_lp_token).burnLiquidty(
    _lp_token, # address of lp token
    _amount,   # amount of lp token being burned to return underlying liquidity
    _data,     # padded bytes (account to send tokens to, whether or not to leave in bento)
    min_out    # padded bytes (token address, min willing to receive of that token... repeated as required.)
  )
  log Remove(_lp_token, msg.sender, _amount)
# 1 love