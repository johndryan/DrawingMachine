class Kritzler {

  Serial port;
  List<Instruction> instructions;
  int currentInst;
  StringBuilder buf = new StringBuilder();

  float tx, ty;
  float scale;
  boolean finished = true;

  /**
   * Constructor, creates a new Kritzler object
   * 
   * @param parent
   *            PApplet object used by main sketch
   * @param port
   *            Serial port set up in main sketch
   */
  Kritzler(PApplet parent, Serial port) {
    this.port = port;
  }

  /**
   * Set the current Instruction list, reset current Instruction count
   * 
   * @param instructions
   *            New set of Instructions
   */
  void setInstructions(List<Instruction> instructions) {
    this.instructions = instructions;
    this.currentInst = 0;
    this.finished = false;
  }

  /**
   * Returns the instructions in use
   * 
   * @return Instruction set in use by Kritzler
   */
  public List<Instruction> getInstructions() {
    return instructions;
  }

  /**
   * Offsets all Instructions by supplied values.
   * 
   * Values should correspond to coordinate of top-left corner of physical
   * canvas.
   * 
   * @param x
   *            X offset
   * @param y
   *            Y offset
   */
  void translate(float x, float y) {
    this.tx = x;
    this.ty = y;
  }

  /**
   * Set the scale factor
   * 
   * @param s
   *            Scale factor (1 = no scaling)
   */
  void setScale(float s) {
    this.scale = s;
  }

  /**
   * Determine whether or not the current Instruction is the final Instruction
   * 
   * @return True if current instruction is final instruction, false if not
   */
  public boolean isFinished() {
    return finished;
  }

  /**
   * Check the Serial port for new messages
   */
  void checkSerial() {
    if (port != null && port.available() > 0)
      processSerial();
  }

  /**
   * Process any incoming Serial messages coming from the Arduino
   */
  void processSerial() {
    while (port.available() > 0) {
      int c = port.read();

      // Fill the buffer until carriage return is received
      if (c != 10) {
        buf.append((char) c);

        // Process buffer
      } 
      else {
        // Retrieve complete message from Serial buffer, then reset
        // buffer
        String message = buf.toString();
        buf.setLength(0);

        // Remove the last character (line break)
        if (message.length() > 0) {
          message = message.substring(0, message.length() - 1);
        }

        // Send "#" messages to console, others to processMessage
        if (message.startsWith("#")) {
          System.out.println("bot: " + message);
        } 
        else {
          processMessage(message);
        }
      }
    }
  }

  /**
   * Processes messages sent from the Serial port from the Arduino
   * 
   * @param message
   *            Message sent from Arduino
   */
  void processMessage(String message) {
    if (message.equals("OK")) {
      System.out.println("received ok");
      if (instructions != null) {
        if (finished) {
          System.out.println("nothing to do");
        } 
        else {
          Instruction inst = instructions.get(currentInst);
          currentInst++;
          sendInstruction(inst);
        }
        if (currentInst >= instructions.size()) {
          //Move to Origin (JDR)
          System.out.println("FINISHED: --> RETURNING TO HOME <--");
          Instruction inst = new Instruction(Instruction.MOVE_ABS, 6425, 6425);
          sendInstruction(inst);
          
          finished = true;
          currentInst--;  // reset to the last position
        }
      }
    } 
    else {
      System.out.println("unknown: " + message);
    }
  }

  /**
   * Processes and sends Serial command based on supplied Instruction
   * 
   * @param i
   *            Instruction to send
   */
  void sendInstruction(Instruction i) {
    // Abort if Serial port is unavailable
    if (port == null)
      return;

    // Prepare variables for output
    String msg = null;
    int x = (int) (i.x * scale);
    int y = (int) (i.y * scale);

    // Generate the actual command
    switch (i.type) {
    case Instruction.MOVE_ABS:
      msg = "M " + (int) (x + tx) + " " + (int) (y + ty) + '\r';
      break;
    case Instruction.LINE_ABS:
      msg = "L " + (int) (x + tx) + " " + (int) (y + ty) + '\r';
      break;
    }
    
    // Output message to console and write to Serial port
    System.out.println("sending (" + currentInst + "): " + msg);
    port.write(msg);
  }
  
  int getCurrentInstructionIndex() {
    return currentInst;
  }

}

