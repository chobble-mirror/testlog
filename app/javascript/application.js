// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"

// Handle equipment selection in inspection form
document.addEventListener("turbo:load", function() {
  const equipmentSelect = document.querySelector('select[name="inspection[equipment_id]"]');
  if (equipmentSelect) {
    // Fields that will be populated from equipment
    const serialField = document.querySelector('input[name="inspection[serial]"]');
    const locationField = document.querySelector('input[name="inspection[location]"]');
    const manufacturerField = document.querySelector('input[name="inspection[manufacturer]"]');
    
    // Function to toggle field state based on equipment selection
    const toggleFieldState = (selectedId) => {
      const hasEquipment = !!selectedId;
      
      // Disable/enable fields
      serialField.disabled = hasEquipment;
      locationField.disabled = hasEquipment;
      manufacturerField.disabled = hasEquipment;
      
      // Add/remove visual indication
      [serialField, locationField, manufacturerField].forEach(field => {
        if (hasEquipment) {
          field.classList.add('equipment-controlled');
        } else {
          field.classList.remove('equipment-controlled');
        }
      });
    };
    
    // Initial state
    toggleFieldState(equipmentSelect.value);
    
    // Handle changes
    equipmentSelect.addEventListener('change', function() {
      const selectedEquipmentId = this.value;
      
      if (selectedEquipmentId) {
        // Fetch equipment details
        fetch(`/equipment/${selectedEquipmentId}.json`)
          .then(response => response.json())
          .then(data => {
            // Populate form fields with equipment data
            serialField.value = data.serial || '';
            locationField.value = data.location || '';
            manufacturerField.value = data.manufacturer || '';
            
            // Update field state
            toggleFieldState(selectedEquipmentId);
          })
          .catch(error => console.error('Error fetching equipment details:', error));
      } else {
        // Clear fields if no equipment selected
        serialField.value = '';
        locationField.value = '';
        manufacturerField.value = '';
        
        // Update field state
        toggleFieldState(null);
      }
    });
  }
});
