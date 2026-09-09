import { beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("../../src/config/env.js", () => ({
  env: { JWT_SECRET: "test-secret", JWT_EXPIRES_IN: "1h" },
}));

vi.mock("argon2", () => ({
  default: { verify: vi.fn() },
}));

vi.mock("jsonwebtoken", () => ({
  default: { sign: vi.fn(() => "signed-token") },
}));

vi.mock("../../src/modules/auth/auth.repository.js", () => ({
  findUserByEmailWithRole: vi.fn(),
}));

const argon2 = (await import("argon2")).default;
const jwt = (await import("jsonwebtoken")).default;
const authRepository = await import("../../src/modules/auth/auth.repository.js");
const { login } = await import("../../src/modules/auth/auth.service.js");
const { UnauthorizedError } = await import("../../src/utils/errors.js");

const verifyMock = vi.mocked(argon2.verify);
const signMock = vi.mocked(jwt.sign);
const findUserMock = vi.mocked(authRepository.findUserByEmailWithRole);

const activeUser = {
  id: "user-1",
  email: "admin@example.com",
  name: "Development Admin",
  passwordHash: "$argon2id$stored-hash",
  isActive: true,
  role: { name: "ADMIN" },
};

const credentials = { email: "admin@example.com", password: "correct-password" };

async function loginError(): Promise<unknown> {
  return login(credentials).then(
    () => {
      throw new Error("expected login to reject");
    },
    (error: unknown) => error,
  );
}

beforeEach(() => {
  vi.clearAllMocks();
  signMock.mockReturnValue("signed-token" as never);
});

describe("login", () => {
  it("rejects an unknown email without ever hashing a password", async () => {
    findUserMock.mockResolvedValue(null);

    const error = await loginError();

    expect(error).toBeInstanceOf(UnauthorizedError);
    expect((error as Error).message).toBe("Invalid email or password");
    expect(verifyMock).not.toHaveBeenCalled();
  });

  it("rejects an inactive account", async () => {
    findUserMock.mockResolvedValue({ ...activeUser, isActive: false } as never);

    const error = await loginError();

    expect(error).toBeInstanceOf(UnauthorizedError);
    expect((error as Error).message).toBe("User account is inactive");
    expect(verifyMock).not.toHaveBeenCalled();
  });

  it("rejects a wrong password with the same message as an unknown email", async () => {
    findUserMock.mockResolvedValue(activeUser as never);
    verifyMock.mockResolvedValue(false as never);

    const error = await loginError();

    expect(error).toBeInstanceOf(UnauthorizedError);
    expect((error as Error).message).toBe("Invalid email or password");
    expect(verifyMock).toHaveBeenCalledWith(
      "$argon2id$stored-hash",
      "correct-password",
    );
  });

  it("issues a token for valid credentials", async () => {
    findUserMock.mockResolvedValue(activeUser as never);
    verifyMock.mockResolvedValue(true as never);

    const result = await login(credentials);

    expect(result).toEqual({
      accessToken: "signed-token",
      user: {
        id: "user-1",
        email: "admin@example.com",
        name: "Development Admin",
        role: "ADMIN",
      },
    });

    expect(signMock).toHaveBeenCalledWith(
      { role: "ADMIN" },
      "test-secret",
      expect.objectContaining({ subject: "user-1" }),
    );
  });
});
