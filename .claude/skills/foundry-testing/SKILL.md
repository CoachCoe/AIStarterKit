---
name: foundry-testing
description: "Foundry testing patterns for Solidity contracts. Triggers: test, testing, forge test, coverage, solidity test"
---

# Foundry Testing Patterns

## When to Activate

- Writing new contract tests
- Setting up test fixtures
- Testing upgradeable contracts
- Integration testing across contracts

## Global Invariants

| Rule | Enforcement |
|------|-------------|
| Inherit from Test base | REQUIRED |
| Use vm.prank for caller | REQUIRED |
| Test revert conditions | REQUIRED |
| Name tests descriptively | test_Action or test_RevertWhen_Condition |

## Test Setup Pattern

```solidity
// test/Base.t.sol
abstract contract BaseTest is Test {
    MyContract public myContract;
    MockERC20 public token;

    address public admin = makeAddr("admin");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");

    function setUp() public virtual {
        // Deploy with proxies (if upgradeable)
        MyContract impl = new MyContract();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl),
            abi.encodeCall(MyContract.initialize, (admin))
        );
        myContract = MyContract(address(proxy));

        // Deploy mock token
        token = new MockERC20();

        // Fund test accounts
        vm.deal(user1, 100 ether);
        token.mint(user1, 1000e18);
    }
}
```

## Test Naming Convention

| Pattern | Example |
|---------|---------|
| Happy path | `test_CreateOrder` |
| Revert condition | `test_RevertWhen_InsufficientBalance` |
| Edge case | `test_CreateOrder_WithZeroAmount` |
| Fuzz test | `testFuzz_Transfer(uint256 amount)` |

## Common Test Patterns

### Testing Basic Operations

```solidity
function test_CreateOrder() public {
    vm.prank(user1);
    uint256 orderId = myContract.createOrder(100);

    assertEq(myContract.ownerOf(orderId), user1);
    assertTrue(myContract.isActive(orderId));
}
```

### Testing Reverts

```solidity
function test_RevertWhen_NotOwner() public {
    vm.prank(user1);
    uint256 orderId = myContract.createOrder(100);

    vm.prank(user2);  // Not the owner
    vm.expectRevert("Not owner");
    myContract.cancelOrder(orderId);
}
```

### Testing with Pranks

```solidity
function test_AdminFunction() public {
    vm.prank(admin);
    myContract.pause();

    assertTrue(myContract.paused());
}

function test_MultipleActions() public {
    vm.startPrank(user1);
    uint256 id = myContract.createOrder(100);
    myContract.updateOrder(id, 200);
    vm.stopPrank();
}
```

### Testing Events

```solidity
function test_EmitsEvent() public {
    vm.expectEmit(true, true, false, true);
    emit OrderCreated(1, user1, 100);

    vm.prank(user1);
    myContract.createOrder(100);
}
```

### Testing with Value

```solidity
function test_DepositNativeToken() public {
    vm.prank(user1);
    uint256 depositId = myContract.deposit{value: 1 ether}();

    assertEq(address(myContract).balance, 1 ether);
}
```

## Mock Contracts

### MockERC20

```solidity
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock", "MOCK") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
```

## Fuzz Testing

```solidity
function testFuzz_Transfer(uint256 amount) public {
    vm.assume(amount > 0 && amount <= 1000e18);

    token.mint(user1, amount);

    vm.prank(user1);
    token.transfer(user2, amount);

    assertEq(token.balanceOf(user2), amount);
}
```

## Fork Testing

```solidity
function test_WithPaseoFork() public {
    vm.createSelectFork("paseo");

    // Test against real Paseo state
    MyContract live = MyContract(DEPLOYED_ADDRESS);
    assertTrue(live.isActive());
}
```

## Integration Test Pattern

```solidity
function test_FullWorkflow() public {
    // 1. Setup
    vm.prank(user1);
    uint256 orderId = myContract.createOrder(100);

    // 2. Fund order
    vm.prank(user1);
    token.approve(address(myContract), 100);
    vm.prank(user1);
    myContract.fundOrder(orderId, 100);

    // 3. Execute
    vm.prank(admin);
    myContract.executeOrder(orderId);

    // 4. Verify final state
    assertEq(myContract.status(orderId), Status.Completed);
}
```

## Running Tests

```bash
# All tests
forge test

# Verbose output
forge test -vvv

# Specific file
forge test --match-path test/MyContract.t.sol

# Specific test
forge test --match-test test_CreateOrder

# Gas report
forge test --gas-report

# Coverage
forge coverage
```

## Anti-Patterns

| Pattern | Status | Reason |
|---------|--------|--------|
| Test without assertions | FORBIDDEN | Tests must verify state |
| Skip revert tests | FORBIDDEN | Security critical |
| Hardcode addresses | FORBIDDEN | Use makeAddr() |
| Forget vm.prank | FORBIDDEN | Wrong msg.sender |
| Test implementation directly | FORBIDDEN | Test via proxy |

---

## Verification (REQUIRED before marking complete)

```bash
# All tests pass
forge test -vvv

# Check coverage (minimum 80%)
forge coverage

# No formatting issues
forge fmt --check

# Gas report for optimization
forge test --gas-report
```

### Checklist

- [ ] All tests pass (`forge test`)
- [ ] Coverage >= 80% (`forge coverage`)
- [ ] All revert conditions tested
- [ ] Proxy tests use proxy address, not implementation
- [ ] Access control tests for all privileged functions
- [ ] Edge cases covered (zero amounts, max values, etc.)
