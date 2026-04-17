import Foundation

/// Prompt injection defense + input hygiene.
///
/// Follows the Merkur-Prompt-Strategy wiki guidelines:
/// - Strip injection-critical tokens before feeding user input into the LLM prompt.
/// - Cap length to bound Gemini cost and discourage abuse.
/// - Validate enum-based inputs (e.g. ``ZodiacSign``) via whitelist so a future
///   string-based code path cannot smuggle raw user content into the prompt.
enum PromptSanitizer {
    /// Maximum allowed length for free-text user input (Ask Astara question, etc.)
    /// Keep it below Gemini's output token budget so the combined prompt stays short.
    static let defaultMaxLength = 280

    /// Tokens that most commonly appear in prompt-injection payloads. Matched
    /// case-insensitively and replaced with a single space to preserve word
    /// boundaries without leaving the attacker's structure intact.
    static let forbiddenTokens: [String] = [
        "<|", "|>",
        "```",
        "system:", "assistant:", "user:",
        "ignore previous", "ignore all previous",
        "disregard previous", "disregard all",
        "forget instructions", "forget previous"
    ]

    /// Sanitize raw user-supplied text before embedding it in an LLM prompt.
    ///
    /// Steps: trim whitespace → strip forbidden tokens → collapse repeated
    /// whitespace → cap length.
    static func sanitizeUserInput(
        _ raw: String,
        maxLength: Int = defaultMaxLength
    ) -> String {
        var result = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        for token in forbiddenTokens {
            result = result.replacingOccurrences(
                of: token,
                with: " ",
                options: .caseInsensitive
            )
        }

        // Collapse runs of whitespace/newlines introduced by replacements.
        let whitespace = CharacterSet.whitespacesAndNewlines
        let pieces = result.unicodeScalars
            .split(whereSeparator: { whitespace.contains($0) })
            .map(String.init)
        result = pieces.joined(separator: " ")

        if result.count > maxLength {
            result = String(result.prefix(maxLength))
        }

        return result
    }

    /// Whitelist validation for zodiac sign inputs. Enum already provides
    /// compile-time safety; this is a runtime belt-and-suspenders check for
    /// any future code path that converts a raw string back to ``ZodiacSign``.
    static func validateSign(_ sign: ZodiacSign) -> Bool {
        ZodiacSign.allCases.contains(sign)
    }
}
