---
paths: "**/*.py"
---

# Python コーディングルール

## 型設計

### 不変な値オブジェクト

```python
from dataclasses import dataclass

@dataclass(frozen=True)
class UserId:
    value: str

    def __post_init__(self) -> None:
        if not self.value:
            raise ValueError("UserId cannot be empty")
```

### Protocol で依存性逆転

```python
from typing import Protocol

class UserRepository(Protocol):
    def find_by_id(self, user_id: UserId) -> User | None: ...
    def save(self, user: User) -> None: ...

# 使用側で定義、実装側は Protocol を知らなくてよい
```

### TypedDict で辞書の型付け

```python
from typing import TypedDict, NotRequired

class UserDict(TypedDict):
    id: str
    name: str
    email: NotRequired[str]  # オプショナル
```

## エラーハンドリング

### カスタム例外

```python
class DomainError(Exception):
    """ドメイン層の基底例外"""

class UserNotFoundError(DomainError):
    def __init__(self, user_id: str) -> None:
        self.user_id = user_id
        super().__init__(f"User not found: {user_id}")
```

### Result 型パターン

```python
from dataclasses import dataclass
from typing import Generic, TypeVar

T = TypeVar("T")
E = TypeVar("E", bound=Exception)

@dataclass(frozen=True)
class Ok(Generic[T]):
    value: T

@dataclass(frozen=True)
class Err(Generic[E]):
    error: E

type Result[T, E] = Ok[T] | Err[E]

# 使用例
def parse_int(s: str) -> Result[int, ValueError]:
    try:
        return Ok(int(s))
    except ValueError as e:
        return Err(e)
```

### アンチパターン

```python
# Bad: bare except
try:
    do_something()
except:
    pass

# Bad: 広すぎる例外
try:
    do_something()
except Exception:
    log.error("failed")

# Good: 具体的な例外をキャッチ
try:
    do_something()
except (ValueError, KeyError) as e:
    log.error("failed", error=str(e))
    raise
```

## 非同期処理

### asyncio 基本パターン

```python
import asyncio
from collections.abc import Sequence

async def fetch_users(ids: Sequence[str]) -> list[User]:
    # 並行実行
    tasks = [fetch_user(id) for id in ids]
    return await asyncio.gather(*tasks)

async def fetch_with_timeout(url: str, timeout: float = 10.0) -> Response:
    async with asyncio.timeout(timeout):
        return await fetch(url)
```

### キャンセル処理

```python
async def worker(queue: asyncio.Queue[Task]) -> None:
    try:
        while True:
            task = await queue.get()
            await process(task)
            queue.task_done()
    except asyncio.CancelledError:
        # クリーンアップ処理
        raise  # 再送出必須
```

## ロギング

### structlog 推奨

```python
import structlog

log = structlog.get_logger()

def process_user(user_id: str) -> None:
    log.info("processing_user", user_id=user_id)
    try:
        result = do_process(user_id)
        log.info("user_processed", user_id=user_id, result=result)
    except Exception:
        log.exception("process_failed", user_id=user_id)
        raise
```

### コンテキスト付きログ

```python
log = log.bind(request_id=request_id, user_id=user_id)
log.info("operation_started")  # 自動的にコンテキストが付与
```

## テスト (pytest)

### 基本構造

```python
import pytest

class TestUserService:
    def test_create_user_with_valid_data_returns_user(self) -> None:
        # Arrange
        sut = UserService(repository=FakeUserRepository())

        # Act
        actual = sut.create_user(name="Alice")

        # Assert
        assert actual.name == "Alice"

    def test_create_user_with_empty_name_raises_error(self) -> None:
        sut = UserService(repository=FakeUserRepository())

        with pytest.raises(ValueError, match="name cannot be empty"):
            sut.create_user(name="")
```

### パラメータ化テスト

```python
@pytest.mark.parametrize(
    ("input", "expected"),
    [
        ("1", 1),
        ("42", 42),
        ("-1", -1),
    ],
)
def test_parse_int_with_valid_input_returns_int(input: str, expected: int) -> None:
    assert parse_int(input) == expected
```

### Fixture

```python
@pytest.fixture
def fake_repository() -> FakeUserRepository:
    return FakeUserRepository()

@pytest.fixture
def sut(fake_repository: FakeUserRepository) -> UserService:
    return UserService(repository=fake_repository)

def test_get_user(sut: UserService, fake_repository: FakeUserRepository) -> None:
    fake_repository.add(User(id="1", name="Alice"))

    actual = sut.get_user("1")

    assert actual.name == "Alice"
```

## コードスタイル

```python
# Good: 早期リターン
def process(data: Data | None) -> Result:
    if data is None:
        return Error("no data")
    if not data.is_valid():
        return Error("invalid")
    return Ok(transform(data))

# Good: Pathlib
from pathlib import Path
config_path = Path("config") / "settings.toml"
content = config_path.read_text()

# Good: f-string
message = f"User {user.name} created at {user.created_at:%Y-%m-%d}"
```

## ツール設定

```toml
# pyproject.toml
[tool.ruff]
line-length = 100
target-version = "py312"

[tool.ruff.lint]
select = ["E", "F", "I", "UP", "B", "SIM", "PTH"]

[tool.mypy]
strict = true
```
