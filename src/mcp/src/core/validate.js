export function asString(value, field) {
  if (typeof value !== "string" || value.trim() === "") {
    return { code: "INVALID_INPUT", message: `${field} deve essere una stringa non vuota` };
  }
  return value;
}

export function asOptionalString(value, field) {
  if (value === undefined) return undefined;
  if (typeof value !== "string") {
    return { code: "INVALID_INPUT", message: `${field} deve essere una stringa` };
  }
  return value;
}

export function asOptionalInt(value, field, min, max) {
  if (value === undefined) return undefined;
  if (typeof value !== "number" || !Number.isInteger(value) || value < min || value > max) {
    return { code: "INVALID_INPUT", message: `${field} deve essere un intero tra ${min} e ${max}` };
  }
  return value;
}

export function asOptionalBoolean(value, field) {
  if (value === undefined) return undefined;
  if (typeof value !== "boolean") {
    return { code: "INVALID_INPUT", message: `${field} deve essere boolean` };
  }
  return value;
}

export function isValidationError(value) {
  return !!value && typeof value === "object" && value.code === "INVALID_INPUT";
}
