package org.hoetten.bioenergie;

public class Vertex {
	private int id;
	private String label;
	
	public Vertex(int id, String label) {
		this.id = id;
		this.label = label;
	}

	/**
	 * Holt id.
	 * @return the id
	 */
	public int getId() {
		return id;
	}

	/**
	 * Setzt id.
	 * @param id the id to set
	 */
	public void setId(int id) {
		this.id = id;
	}

	/**
	 * Holt label.
	 * @return the label
	 */
	public String getLabel() {
		return label;
	}

	/**
	 * Setzt label.
	 * @param label the label to set
	 */
	public void setLabel(String label) {
		this.label = label;
	}

	/* (non-Javadoc)
	 * @see java.lang.Object#toString()
	 */
	@Override
	public String toString() {
		return "Vertex [id=" + getId() + ", label=" + getLabel()
				+ "]";
	}
}
