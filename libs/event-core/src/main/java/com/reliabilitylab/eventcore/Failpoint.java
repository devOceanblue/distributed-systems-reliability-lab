package com.reliabilitylab.eventcore;

public final class Failpoint {
  private Failpoint() {
  }

  public static void check(String envName) {
    String value = System.getenv(envName);
    if (value != null && value.equalsIgnoreCase("true")) {
      throw new IllegalStateException("Failpoint triggered: " + envName);
    }
  }
}
