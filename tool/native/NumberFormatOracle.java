import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.Locale;

/** Isolated Java Formatter oracle for the recovered NUMBER display rule. */
public final class NumberFormatOracle {
  public static void main(String[] args) throws Exception {
    Locale.setDefault(Locale.US);
    System.out.println("META\t" + System.getProperty("java.version") + "\t" + Locale.US.toLanguageTag());
    try (BufferedReader input = new BufferedReader(new InputStreamReader(System.in))) {
      String line;
      while ((line = input.readLine()) != null) {
        String[] fields = line.split("\\t", -1);
        double raw = Double.parseDouble(fields[0]);
        double multiplier = Double.parseDouble(fields[1]);
        double divisor = Double.parseDouble(fields[2]);
        double additiveOffset = Double.parseDouble(fields[3]);
        double value = raw * multiplier / divisor + additiveOffset;
        String format = multiplier == 1.0 && divisor == 1.0 ? "%.0f" : "%.2f";
        System.out.println(Double.toHexString(value) + "\t" + String.format(Locale.US, format, value));
      }
    }
  }
}
